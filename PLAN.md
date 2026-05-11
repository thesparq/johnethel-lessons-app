# Plan

## Current Architecture (Post-Security-Scheme)

```
Browser → Static Agent (html/js/config.js)
        → fetch() → Golem API Gateway (JWT validation via Security Scheme)
                   → ApiAgent (role extraction, routing) → UserAgent (data, cache) → QueryFork → SurrealDB
                                                         → AdminAgent (assignments)
```

| Component | Agent | Type | Role |
|-----------|-------|------|------|
| `api` | **ApiAgent** | Ephemeral | HTTP endpoints, role extraction from OIDC Principal, RPC dispatch |
| `api` | **ToggleFork** | Ephemeral (deprecated) | Provision compat only, no-op |
| `auth` | **AuthAgent** | Durable singleton | Unused currently — Authentik userinfo validation (kept for future) |
| `user` | **UserAgent** | Durable per-user | Lesson data + TTL cache. Owns SurrealDB access. Handles toggles. |
| `user` | **QueryFork** | Ephemeral | Isolated blocking I/O to SurrealDB |
| `admin` | **AdminAgent** | Durable singleton | Teacher-subject assignments |
| `static` | **FileServerAgent** | Ephemeral | Static files (index.html, JS, config.js), SPA catch-all |

**Auth**: Golem API Security Scheme (`johnethel-auth`) validates Authentik JWTs at the gateway.
The gateway injects an `OidcPrincipal` into ApiAgent with `sub` (user_id) and `claims` (raw JWT claims JSON containing `groups`). Role is extracted from the `groups` claim. Only users in `students`, `teachers`, or `admin` groups are allowed.

Toggle state lives in SurrealDB (`lesson_content.active`). Cache is per-user with TTL (10min lists, 5min content). Manual invalidation on toggle.

---

## Phase 1: Core Refactor — DONE

- [x] SurrealDB schema: `active` field on all records
- [x] QueryFork: ephemeral SurrealDB worker
- [x] UserAgent: per-user TTL cache, student filtering, toggle with cache invalidation
- [x] AdminAgent: stripped of toggle state, teacher assignments only
- [x] ApiAgent: HTTP endpoints, role extraction, RPC dispatch
- [x] Frontend: Rabbita SPA, refresh fix (absolute script path), inactive lesson states
- [x] golem.yaml: all 5 components, IFS files, frontend build steps, retry policies
- [x] seed-db.sh: auto-start SurrealDB, create NS/DB, import lessons
- [x] SQL injection validation: subject name + lesson ID sanitization
- [x] Retry policies: `http-transient` policy for 502/503/504 (3 retries, exponential backoff)

---

## Phase 2: Authentik Integration — DONE

- [x] Authentik application + provider created on `auth.johnethel.school`
- [x] Golem API Security Scheme (`johnethel-auth`) configured for Authentik
- [x] `#derive.mount_auth(true)` on ApiAgent — gateway validates all JWTs
- [x] OIDC Principal → user_id (sub) + role (groups claim) extraction
- [x] Group enforcement: only `students`, `teachers`, `admin` allowed
- [x] `/config` endpoint public (exempt from auth via `#derive.endpoint_auth(false)`)
- [x] Frontend OAuth2 login flow with PKCE
- [x] Dynamic `config.js` served from env vars (Authentik URL + client_id)
- [x] All credentials as env vars in golem.yaml
- [x] Env vars for Authentik config on both `api` and `static` components

### Authentik Admin Setup Required

1. Create groups: `students`, `teachers`, `admin` in Authentik
2. Create test users and assign to groups
3. Configure scope mapping to include `groups` claim in JWT
4. Client ID: `rhca5hupVGwRWh2EVf7dkw3WXXFcseJMcsdQYVH9` (configured in golem.yaml env vars)

---

## Phase 3: Polish & Features — TODO

### Step 14: Performance
- [ ] LRU cache eviction with max size
- [ ] Cache metrics (hit rate, size)

### Step 15: Reliability
- [ ] Structured logging (`@logging`)
- [ ] Graceful degradation (serve stale cache on DB failure)
- [ ] Test crash recovery

### Step 16: Features
- [ ] Assessments: new SurrealDB table + UserAgent endpoints
- [ ] Attendance tracking
- [ ] Bulk lesson operations
- [ ] Parent portal agent

---

## Known Issues & Workarounds

### 64KB IFS File Read Limit
- **Status**: Active workaround (32KB chunked reads in FileServerAgent)
- **Fix**: Replace with `@fs.read_bytes()` when Golem SDK fixes land

### Server State Corruption
- **Issue**: Local dev server hangs on outgoing HTTP after extended runtime
- **Fix**: `pkill -f "golem server run"` then `golem server run --clean`

### AuthAgent RPC Panics
- **Issue**: Cross-component RPC to AuthAgent panics (traps) on invocation
- **Status**: AuthAgent not used — auth handled by Golem API Security Scheme
- **Fix**: Keep AuthAgent for potential future use (custom claim validation, /userinfo checks)

### ryota0624/oauth2 Package
- **Issue**: Package is native-only (`"preferred-target": "native"`), incompatible with JS frontend
- **Status**: Not used. PKCE implemented manually via browser Crypto API in JS FFI

---

## Delivery Checklist

- [x] Students browse subjects and lessons
- [x] Teachers see all lessons with active/inactive state
- [x] Students don't see inactive lessons
- [x] Teachers toggle lessons
- [x] Invalid tokens rejected
- [x] Refresh/reload preserves route state
- [x] SQL injection validation
- [x] Retry policies for SurrealDB HTTP
- [x] Authentik OIDC integration with PKCE
- [x] Golem API Security Scheme (gateway-level JWT validation)
- [x] Group-based access control (students/teachers/admin only)
- [x] Env vars for all credentials
- [ ] Authentik group scope mapping + test users
- [ ] LRU cache eviction
- [ ] Structured logging
