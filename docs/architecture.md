# Architecture — Johnethel LMS

## System Overview

The Johnethel LMS is a Golem Cloud application with a Rabbita SPA frontend, Authentik OIDC authentication, and SurrealDB for lesson content. Auth is validated at the Golem API Gateway level (no manual JWT verification in agent code).

## Component Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│  Browser                                                             │
│  ├─ /config.js  (dynamic, from env vars)                             │
│  ├─ /index.html (SPA shell)                                          │
│  └─ /johnethel-frontend.js (Rabbita TEA app, ~640KB)                 │
└──────────────┬───────────────────────────────────────────────────────┘
               │ HTTP
┌──────────────▼───────────────────────────────────────────────────────┐
│  Golem API Gateway (localhost:9006 / localhost:9881)                 │
│  ├─ Security Scheme: johnethel-auth → Authentik OIDC                 │
│  ├─ JWT validation: signature, expiry, issuer, audience              │
│  └─ Principal injection: OidcPrincipal(sub, claims, email, ...)      │
└──────────────┬───────────────────────────────────────────────────────┘
               │ Authenticated only (except /config)
┌──────────────▼───────────────────────────────────────────────────────┐
│  ApiAgent (ephemeral, api component)                                 │
│  ├─ /config          → public, returns Authentik config              │
│  ├─ /subjects        → GET, auth required                            │
│  ├─ /subjects/{id}/lessons → GET, auth required                     │
│  ├─ /lessons/{id}           → GET, auth required                    │
│  ├─ /lessons/{id}/toggle    → POST, teacher/admin only              │
│  └─ /admin/assign           → POST, admin only                      │
│                                                                      │
│  Role extraction from OidcPrincipal.claims.groups                    │
│  Only "students", "teachers", "admin" groups allowed.                │
└───┬──────────────┬──────────────┬────────────────────────────────────┘
    │ RPC          │ RPC          │ RPC
    ▼              ▼              ▼
┌───────────┐ ┌──────────┐ ┌──────────────┐
│ UserAgent │ │AdminAgent│ │  AuthAgent   │
│ (durable, │ │(durable, │ │  (durable,   │
│ per-user) │ │singleton)│ │  singleton)  │
│           │ │          │ │  (unused)    │
│ cache+SQL │ │ teacher  │ │              │
│ ▼         │ │ subjects │ │              │
│ QueryFork │ │          │ │              │
│ (ephemer) │ │          │ │              │
│ ▼         │ │          │ │              │
│ SurrealDB │ │          │ │              │
└───────────┘ └──────────┘ └──────────────┘
```

## Request Flow: Student Browsing Lessons

```
1. Browser loads index.html → loads /config.js (sets window.__CONFIG__)
2. User clicks "Sign in with Authentik"
3. Frontend generates PKCE verifier + challenge (browser Crypto API)
4. Redirect to: https://auth.johnethel.school/application/o/authorize/
   ?client_id=rhca5hupVGwRWh2EVf7dkw3WXXFcseJMcsdQYVH9
   &redirect_uri=http://johnethel-lessons-static.localhost:9006/callback
   &response_type=code&scope=openid+profile+email
   &code_challenge=<SHA256>&code_challenge_method=S256&state=<csrf>
5. User authenticates on Authentik
6. Authentik redirects to: /callback?code=AUTH_CODE&state=csrf
7. Frontend exchanges code for access_token (POST to /token with code_verifier)
8. Frontend stores access_token in localStorage
9. Frontend calls GET /subjects with Authorization: Bearer <access_token>

10. Golem Gateway:
    - Validates JWT signature against Authentik JWKS
    - Checks expiry, issuer (auth.johnethel.school), audience (client_id)
    - Extracts OidcPrincipal → ApiAgent constructor

11. ApiAgent::get_subjects():
    - Parses Principal.claims JSON → extracts "groups" claim
    - Maps groups to role (students→student, teachers→teacher, admin→admin)
    - Rejects if no recognized group found
    - RPC → UserAgent("sub","role").get_subjects()

12. UserAgent::get_subjects():
    - Checks cache with key "subjects" (10min TTL)
    - Cache miss: spawns QueryFork → SurrealDB (SELECT subject ... GROUP BY)
    - Returns JSON array of subjects

13. Response: [{"subject":"English Language"},{"subject":"Mathematics"},...]
    Browser renders subject list via Rabbita TEA

14. Student clicks "Mathematics":
    - GET /subjects/Mathematics/lessons
    - UserAgent::get_lessons("Mathematics"):
      - SQL: SELECT ... WHERE subject = 'Mathematics' ORDER BY week
      - For students: filters out active=false lessons
    - Frontend renders lesson list

15. Student clicks "Introduction to Algebra":
    - GET /lessons/lesson_content:1
    - UserAgent::get_lesson("lesson_content:1"):
      - SQL: SELECT * FROM lesson_content:1
      - Strips teacher-only fields (answers)
    - Frontend renders full lesson content
```

## Request Flow: Teacher Toggling Lesson

```
1. Teacher logs in via Authentik (groups claim contains "teachers")
2. Teacher opens English Language → sees all lessons (active + inactive)
3. Teacher clicks toggle on lesson 8:
   - POST /lessons/lesson_content:8/toggle
   - ApiAgent checks role == "teacher" || "admin"
   - RPC → UserAgent("sub","teacher").toggle_lesson("lesson_content:8")

4. UserAgent::toggle_lesson():
   - QueryFork: SELECT active, subject FROM lesson_content:8 → false, "English Language"
   - QueryFork: UPDATE lesson_content:8 SET active = true
   - Invalidates cache: "content:lesson_content:8" and "list:English Language"
   - Returns new active value

5. Frontend updates UI to show/hide the lesson's active status
```

## Data Flow: Unauthenticated Access

```
1. Browser requests /subjects without token
2. Gateway security scheme: no valid JWT → HTTP 302 to Authentik login
3. Browser redirected to Authentik
```

## Cache Architecture

| Key | TTL | Content | Invalidated By |
|-----|-----|---------|----------------|
| `subjects` | 10 min | Subject list JSON | Manual only |
| `list:{subject}` | 10 min | Lessons for a subject | Toggle, 10min expiry |
| `content:{id}` | 5 min | Full lesson content | Toggle, 5min expiry |

Cache is per-user (per UserAgent instance). Student and teacher have separate caches.
Toggle invalidates only the toggling user's cache. Other users see changes after TTL expires.

## Security Model

| Layer | Mechanism |
|-------|-----------|
| Transport | TLS to Authentik (HTTPS) |
| Authentication | Authentik OIDC → JWT → Golem Security Scheme |
| JWT Validation | Golem gateway (signature, expiry, issuer, audience) |
| Authorization | Groups claim in JWT → role extraction |
| Access Control | Role checks on endpoints (toggle → teacher/admin, assign → admin) |
| Input Sanitization | Subject name + lesson ID validation (whitelist regex) |
| SQL Injection | Parameterized via validation, not SQL string escaping |
| CSRF (OAuth2) | PKCE + state parameter |

## Component Details

### api component
- **ApiAgent**: Ephemeral HTTP router. Receives `OidcPrincipal` from gateway. Extracts role from `groups` claim. Validates subject/lesson IDs. Routes to UserAgent or AdminAgent via RPC.
- **ToggleFork**: Deprecated ephemeral agent. No-op. Kept for provision config compatibility.

### user component
- **UserAgent(user_id, role)**: Durable per-user. Holds `Map[String, (String, UInt64)]` cache. Methods: `get_subjects()`, `get_lessons(subject)`, `get_lesson(lesson_id)`, `toggle_lesson(lesson_id)`.
- **QueryFork(sql)**: Ephemeral. Makes WASI HTTP POST to SurrealDB, returns JSON result. Dies immediately.

### auth component
- **AuthAgent()**: Durable singleton. Currently unused (auth handled by gateway). Has `validate_token()` method that can call Authentik `/userinfo` endpoint. Kept for future custom claim validation.

### admin component
- **AdminAgent()**: Durable singleton. Stores `subject_teacher : Map[String, String]`. Methods: `assign_teacher()`, `get_teacher_for_subject()`.

### static component
- **FileServerAgent()**: Ephemeral. Serves files from IFS with SPA catch-all. Special handling for `/config.js` (generated from env vars). Chunked reads for large JS bundle (64KB IFS workaround).

## Environment Variables

| Component | Variable | Value |
|-----------|----------|-------|
| `api` | `AUTHENTIK_URL` | `https://auth.johnethel.school` |
| `api` | `AUTHENTIK_CLIENT_ID` | `rhca5hupVGwRWh2EVf7dkw3WXXFcseJMcsdQYVH9` |
| `auth` | `AUTHENTIK_USERINFO_URL` | `https://auth.johnethel.school/application/o/userinfo/` |
| `user` | `SURREALDB_URL` | `http://localhost:8000` |
| `user` | `SURREALDB_NS` | `johnethel` |
| `user` | `SURREALDB_DB` | `lessons` |
| `user` | `SURREALDB_TOKEN` | `root` |
| `static` | `AUTHENTIK_URL` | `https://auth.johnethel.school` |
| `static` | `AUTHENTIK_CLIENT_ID` | `rhca5hupVGwRWh2EVf7dkw3WXXFcseJMcsdQYVH9` |

## Frontend (Rabbita SPA)

- **Framework**: Rabbita (TEA architecture)
- **Routes**: `/` (Home), `/subjects/{id}` (SubjectDetail), `/lessons/{id}` (LessonDetail), `/admin`, `/login`, `/callback`
- **Auth**: OAuth2 Authorization Code + PKCE
- **Config**: `window.__CONFIG__` set by `/config.js` (generated from env vars)
- **Key Features**: Student/teacher views, inactive lesson display, role-based controls, refresh-safe routing
