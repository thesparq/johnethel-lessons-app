# Plan

Build in this exact order. Each step must compile before moving to next.

## Phase 1: Core Refactor (SurrealDB + Per-User Cache)

### Step 1: SurrealDB Schema Update
- [ ] Add `active: true` to all lesson records in seed data
- [ ] Update `seed_lessons.surql` with `active` field
- [ ] Re-seed SurrealDB
- [ ] Verify: `SELECT active FROM lesson_content:1` returns `true`

### Step 2: Create AuthAgent Component
- [ ] Create `auth/` directory with `moon.pkg`, `auth_agent.mbt`
- [ ] Implement `AuthAgent` (durable singleton):
  - `new()` — empty state
  - `validate_token(token: String) -> (String, String, String)` — (user_id, role, email)
  - JWKS fetching from Authentik endpoint
  - JWKS caching in durable memory
  - Self-scheduled refresh every hour
- [ ] Add JWT parsing (header, payload, signature verification)
- [ ] Add `auth/rpc_helpers.mbt` if needed
- [ ] Add `auth/moon.pkg` with correct imports
- [ ] `moon build --target wasm` — must pass
- [ ] Update `golem.yaml`:
  - Add `johnethel-lessons-app:auth` component
  - Add env vars: `AUTHENTIK_URL`, `AUTHENTIK_JWKS_URL`
- [ ] `golem deploy`
- [ ] Test: `golem agent invoke "AuthAgent()" "validate_token" '"test|student"'`

### Step 3: Create QueryFork (Ephemeral DB Worker)
- [ ] Create `user/query_fork.mbt`
- [ ] Implement `QueryFork` (ephemeral):
  - `new(sql: String) -> QueryFork`
  - `execute() -> String` — makes WASI HTTP to SurrealDB, returns JSON
- [ ] Move SurrealDB HTTP logic from UserAgent to QueryFork:
  - `surreal_url_parts()`
  - `surrealdb_query()` (now in QueryFork)
  - `str_to_bytes()`, `bytes_to_str()`
- [ ] Fix UTF-8 encoding (multi-byte character handling)
- [ ] Add SQL injection validation: `validate_lesson_id()` regex
- [ ] `moon build --target wasm` — must pass

### Step 4: Refactor UserAgent (HTTP + Cache)
- [ ] Update `user/user_agent.mbt`:
  - Add `#derive.mount("/users/{user_id}")`
  - Add `#derive.mount_cors("*")`
  - Add HTTP endpoints:
    - `get_subjects(auth_header: String) -> String`
    - `get_lessons(auth_header: String, subject: String) -> String`
    - `get_lesson(auth_header: String, lesson_id: String) -> String`
    - `toggle_lesson(auth_header: String, lesson_id: String) -> String`
  - Add cache structure:
    ```moonbit
    struct CacheEntry {
      data: String
      fetched_at: UInt64
      ttl_ms: UInt64
    }
    ```
  - Add token cache:
    ```moonbit
    struct ValidatedToken {
      user_id: String
      role: String
      validated_at: UInt64
      ttl_ms: UInt64
    }
    ```
  - Add LRU eviction with max_cache_bytes limit
  - Add cache helper methods: `check_cache(key)`, `update_cache(key, data)`, `invalidate_cache(key)`
  - Auth flow: extract token → check token_cache → validate via AuthAgent RPC → verify user_id match
  - Business logic: cache check → fork QueryFork → update cache → return
  - Teacher toggle: validate role → fork QueryFork (SELECT + UPDATE) → invalidate cache → return
  - Lesson ID validation before any query
- [ ] Update `user/moon.pkg`:
  - Add `@httpTypes` import for WASI HTTP
  - Add `@fsTypes` if needed
- [ ] Remove old `get_env()`, `surrealdb_query()` from UserAgent (moved to QueryFork)
- [ ] `moon build --target wasm` — must pass

### Step 5: Reduce AdminAgent Scope
- [ ] Update `admin/admin_agent.mbt`:
  - Remove `lesson_toggle_state` (moved to SurrealDB)
  - Keep `subject_teacher` map
  - Keep `assign_teacher()`, `get_teacher_for_subject()`, `list_teachers()`
- [ ] `moon build --target wasm` — must pass

### Step 6: Remove ApiAgent Component
- [ ] Delete `api/api_agent.mbt`
- [ ] Delete `api/rpc_helpers.mbt`
- [ ] Delete `api/jwt.mbt`
- [ ] Keep `api/` directory only if needed for common types (move to `common/` if so)
- [ ] Update `golem.yaml`:
  - Remove `johnethel-lessons-app:api` component
  - Remove ApiAgent from `httpApi` deployments
  - Add UserAgent to `httpApi` deployments

### Step 7: Update golem.yaml
- [ ] Add retry policies:
  ```yaml
  retryPolicyDefaults:
    local:
      http-transient:
        priority: 10
        predicate:
          propIn: { property: "status-code", values: [502, 503, 504] }
        policy:
          countBox:
            maxRetries: 3
            inner:
              exponential:
                baseDelay: "200ms"
                factor: 2.0
  ```
- [ ] Update `httpApi` deployments:
  ```yaml
  httpApi:
    deployments:
      local:
        - domain: johnethel-lessons-app.localhost:9006
          agents:
            UserAgent: {}
        - domain: johnethel-lessons-static.localhost:9006
          agents:
            FileServerAgent: {}
  ```
- [ ] Verify: `golem component manifest-trace`
- [ ] `golem deploy --yes`

### Step 8: Frontend Updates
- [ ] Update API base URL if needed (UserAgent mount path changed)
- [ ] Update endpoint paths:
  - `/subjects` → `/users/{user_id}/subjects`
  - `/subjects/{id}/lessons` → `/users/{user_id}/subjects/{id}/lessons`
  - `/lessons/{id}` → `/users/{user_id}/lessons/{id}`
  - `/lessons/{id}/toggle` → `/users/{user_id}/lessons/{id}/toggle`
- [ ] Extract `user_id` from JWT `sub` claim
- [ ] Include `user_id` in all API call URLs
- [ ] `cd frontend && moon build --target js`
- [ ] Copy JS bundle to `ui/dist/`

### Step 9: Integration Testing
- [ ] Test: `curl /users/anonymous|student/subjects` → returns subject list
- [ ] Test: `curl /users/anonymous|student/subjects/Mathematics/lessons` → returns lessons
- [ ] Test: `curl /users/anonymous|student/lessons/lesson_content:1` → returns lesson (active: true)
- [ ] Test: Login as teacher, toggle lesson off
- [ ] Test: `curl /users/teacher|teacher/lessons/lesson_content:1` → returns lesson (active: false)
- [ ] Test: Anonymous user still sees active: true (cache) then active: false (after TTL)
- [ ] Test: Refresh on `/users/{id}/lessons/{id}` serves index.html (SPA catch-all)
- [ ] Test: Browser navigation (click links, back button)

---

## Phase 2: Authentik Integration

### Step 10: Authentik Configuration
- [ ] Create Authentik application: "johnethel-lms"
- [ ] Create OAuth2/OIDC provider
- [ ] Configure redirect URI: `http://johnethel-lessons-static.localhost:9006/callback`
- [ ] Create groups: `students`, `teachers`, `admin`
- [ ] Create test users and assign to groups
- [ ] Note JWKS endpoint URL

### Step 11: AuthAgent JWKS Integration
- [ ] Set `AUTHENTIK_JWKS_URL` in `golem.yaml` env vars
- [ ] Update AuthAgent to fetch JWKS from Authentik (not hardcoded)
- [ ] Test: Validate real Authentik JWT

### Step 12: Frontend OAuth2 Flow
- [ ] Implement login button → redirect to Authentik `/authorize`
- [ ] Implement callback handler → exchange code for tokens
- [ ] Store access_token + refresh_token in localStorage
- [ ] Implement token refresh (before expiry)
- [ ] Remove simple `user|role` token format (or keep for dev mode only)

### Step 13: End-to-End Auth Test
- [ ] Student logs in via Authentik → browses subjects → views lesson
- [ ] Teacher logs in via Authentik → toggles lesson
- [ ] Admin logs in → assigns teacher to subject
- [ ] Verify role-based access control works

---

## Phase 3: Optimizations (Post-MVP)

### Step 14: Performance
- [ ] Add token cache in UserAgent (1 min TTL)
- [ ] Add LRU cache eviction with max size
- [ ] Add cache metrics (hit rate, size)
- [ ] Tune TTL values based on usage patterns

### Step 15: Reliability
- [ ] Add structured logging (`@logging` module)
- [ ] Add error tracking / alerting
- [ ] Add graceful degradation (serve stale cache on DB failure)
- [ ] Test crash recovery (`golem agent simulate-crash`)

### Step 16: Features
- [ ] Assessments: new SurrealDB table + UserAgent endpoints
- [ ] Attendance: UserAgent `mark_attendance()`
- [ ] Notifications: `schedule_future_call()` for reminders
- [ ] Bulk operations: `@api.fork()` for parallel lesson updates
- [ ] Parent portal: new `ParentAgent` component

---

## Known Issues & Workarounds

### 64KB IFS File Read Limit
- **Status**: Active workaround
- **Code**: `static/static_agent.mbt` — `read_file_bytes()` with 32KB chunks
- **Future**: Replace with `@fs.read_bytes()` when Golem SDK fix lands (PR #3333)

### WASI HTTP Blocking
- **Status**: Mitigated by QueryFork pattern
- **Issue**: No built-in RPC timeout
- **Workaround**: Ephemeral QueryFork isolates blocking I/O

### String Encoding (UTF-16 → UTF-8)
- **Status**: Needs fix
- **Issue**: `str_to_bytes` may corrupt multi-byte characters
- **Fix**: Use proper UTF-8 encoder (check MoonBit SDK)

---

## Done When

- [ ] Student can log in via Authentik, browse subjects, open a lesson
- [ ] Teacher can log in and toggle a lesson off/on
- [ ] Anonymous browsing works (no login required for read endpoints)
- [ ] Cache provides < 5ms response for cached data
- [ ] No timeouts on lesson detail pages
- [ ] All 12 seeded lessons display correctly with full content
