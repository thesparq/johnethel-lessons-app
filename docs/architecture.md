# Architecture

## System Overview

The Johnethel LMS is a multi-component Golem application serving a Rabbita frontend.
Auth is delegated to Authentik (OAuth2). All lesson data lives in SurrealDB.
Each user gets their own durable UserAgent instance with per-user caching.

## Components

```
components/
├── auth/       AuthAgent — durable singleton, JWKS caching, JWT validation
├── user/       UserAgent — durable per-user, caching, orchestrates QueryFork
│   └── query_fork.mbt — ephemeral SurrealDB worker
├── admin/      AdminAgent — durable singleton, teacher-subject assignments
└── static/     FileServerAgent — ephemeral, serves frontend via IFS
```

## Agent Types

### AuthAgent — Durable Singleton
- Caches Authentik JWKS in durable memory
- Validates JWT signatures and claims
- Returns `(user_id, role, email)` or error
- Refreshes JWKS every hour via self-scheduled call
- **Why durable**: JWKS cache must survive restarts

### UserAgent — Durable Per-User
- Mount: `/users/{user_id}` (HTTP routing from Golem gateway)
- State (durable):
  - `cache : Map[String, CacheEntry]` — lesson data with TTL
  - `token_cache : Map[String, ValidatedToken]` — JWT validation results (1 min TTL)
  - `preferences : Map[String, Json]` — UI settings (future)
  - `progress : Map[String, Bool]` — lesson completion (future)
  - `assessment_scores : Map[String, Json]` — (future)
  - `attendance : Array[String]` — (future)
- Per-request flow:
  1. Extract `Authorization` header
  2. Check `token_cache` — if fresh, skip to step 5
  3. RPC → `AuthAgent.validate_token(jwt)` → `(user_id, role, email)`
  4. Store in `token_cache`
  5. Verify `returned_user_id == self.user_id`
  6. Execute business logic (cache check → fork QueryFork → return)
- **Never blocks on I/O directly** — always forks QueryFork
- Cache strategy:
  - Key: `"subjects"`, `"list:{subject}"`, `"content:{id}"`
  - TTL: 5 min for lesson content, 10 min for lists
  - LRU eviction when cache exceeds max size
  - On teacher toggle: invalidate own cache, update DB

### QueryFork — Ephemeral
- Stateless SurrealDB HTTP client
- Makes blocking WASI HTTP requests to SurrealDB
- Returns JSON result, dies immediately
- **Why ephemeral**: If request hangs, only this instance dies; UserAgent stays responsive

### AdminAgent — Durable Singleton
- `subject_teacher : Map[String, String]` — which teacher owns which subject
- `list_teachers()`, `assign_teacher(teacher_id, subject)`
- No toggle state (lives in SurrealDB `lesson_content.active`)
- **Why durable**: Teacher assignments must survive restarts

### FileServerAgent — Ephemeral
- Serves `index.html` and JS bundle via IFS
- SPA catch-all `/{*path}` returns `index.html`
- **64KB read workaround**: chunked reading in `read_file_bytes()`

## Request Flows

### Student Browses Subjects
```
Browser → GET /users/alice123/subjects (Bearer <jwt>)
→ Gateway → UserAgent("alice123")::get_subjects(jwt)
  → Check token_cache → miss
    → AuthAgent.validate_token(jwt) → ("alice123", "student", ...)
    → Store in token_cache
  → Verify "alice123" == self.user_id ✓
  → Check cache["subjects"]: miss/stale
    → Fork QueryFork("SELECT subject FROM lesson_content GROUP BY subject;")
    → QueryFork returns JSON → dies
  → Update cache["subjects"] = (json, now)
  → Return JSON
```
**Latency**: ~101ms first time, ~1ms cached.

### Student Views Lesson (Cache Hit)
```
Browser → GET /users/alice123/lessons/lesson_content:1
→ UserAgent checks cache["content:lesson_content:1"]
→ Fetched at t=0, TTL=5min, now t=2min → FRESH
→ Return cached JSON (includes active: true/false)
```
**Latency**: ~1ms.

### Teacher Toggles Lesson
```
Browser → POST /users/teacher456/lessons/lesson_content:1/toggle
→ UserAgent("teacher456")::toggle_lesson(jwt, "lesson_content:1")
  → AuthAgent.validate_token(jwt) → ("teacher456", "teacher", ...)
  → Verify role == "teacher"
  → Fork QueryFork:
    1. "SELECT active FROM lesson_content:1"
    2. "UPDATE lesson_content:1 SET active = false"
  → Invalidate cache["content:lesson_content:1"]
  → Return {"toggled": false, "active": false}
```
**Latency**: ~101ms.

### Auth Flow (Authentik OAuth2)
```
1. User clicks "Johnethel LMS" in Authentik dashboard
2. Authentik redirects to LMS callback with ?code=...
3. Frontend exchanges code for access_token + id_token
4. Frontend stores tokens in localStorage
5. Every API request includes Authorization: Bearer <access_token>
6. UserAgent validates via AuthAgent on every request (cached for 1 min)
```

## Parallel Workers

Golem provides two parallel execution patterns:

### 1. Ephemeral Child Agents (Already Used)
`UserAgent` forks `QueryFork` for blocking I/O. This is the primary parallel pattern in the LMS.

### 2. `@api.fork()` — Clone Agent with State
Clones the current agent at the current execution point, creating a phantom agent that inherits the parent's state.

**When useful for LMS**:
- **Bulk operations**: A teacher updates 10 lessons at once → fork 10 QueryForks in parallel
- **Assessment grading**: Grade multiple submissions simultaneously
- **Analytics queries**: Run multiple reports in parallel

**Current decision**: Single QueryFork per request is sufficient for MVP.
**Future**: Use `@api.fork()` or child agent fan-out for bulk operations.

Example (future):
```moonbit
// Fan-out: fetch 5 lessons in parallel
let promise_ids : Array[@types.PromiseId] = []
for lesson_id in lesson_ids {
  let pid = @api.create_promise()
  promise_ids.push(pid)
  match @api.fork() {
    Original(_) => ()
    Forked(_) => {
      let data = QueryFork::execute("SELECT * FROM " + lesson_id)
      let _ = @api.complete_promise(pid, str_to_bytes(data))
      return
    }
  }
}
// Collect all results
let results : Array[String] = []
for pid in promise_ids {
  let bytes = @api.await_promise(pid)
  results.push(bytes_to_str(bytes))
}
```

## Security

| Threat | Mitigation |
|--------|-----------|
| JWT spoofing | AuthAgent verifies signature against Authentik JWKS |
| Identity mismatch | UserAgent verifies `returned_user_id == self.user_id` |
| Unauthorized toggle | Role check `role == "teacher"` + AdminAgent assignment |
| SQL injection | Validate `lesson_id` format (`lesson_content:\d+`) |
| CORS | `mount_cors("*")` on UserAgent (restrict in prod) |
| Token replay | Short token lifetime (15 min) + refresh flow |
| Cache poisoning | Per-user cache, only stores own query results |
| Information leakage | Teacher fields filtered before caching |

## Data Model (SurrealDB)

```sql
-- lesson_content table (existing)
CREATE lesson_content:1 CONTENT {
  topic_title: "Introduction to Algebra",
  subject: "Mathematics",
  term: "Term 1",
  week: 1,
  active: true,  -- NEW: toggle field
  introduction: "...",
  content_sections: [...],
  key_points: [...],
  conclusion: "...",
  materials: [...],
  objectives: [...],
  duration_mins: 45,
  teacher_tips: "...",          -- filtered for students
  formative_assessment: "...",  -- filtered for students
  summative_assessment: "...",  -- filtered for students
  remediation: "...",           -- filtered for students
  lesson_steps: [...]           -- teacher_actions/assessment filtered
};

-- Future tables
-- assessments, attendance, teacher_assignments
```

## Failure Modes

| Scenario | Behavior | Recovery |
|----------|----------|----------|
| SurrealDB down | QueryFork hangs → error returned | Retry policy in golem.yaml. Return stale cache if available. |
| AuthAgent down | JWT validation fails → 401 | Durable agent survives restarts. Delete/recreate if corrupted. |
| UserAgent deleted | Recreated on next request with empty cache | Cache rebuilt on demand. Durable state (progress, attendance) lost. |
| Golem restart | Agents resume from oplog | Durable state restored. Ephemeral agents recreated. |
| Authentik down | New logins fail → 401 | Existing valid tokens work until expiry. |

## Critical Design Decisions

1. **Toggle in SurrealDB, not AdminAgent**: Simpler, one source of truth, no propagation complexity. Cache handles staleness.
2. **UserAgent caches, not QueryFork**: QueryFork is stateless and dies. Cache lives in durable UserAgent.
3. **Token cache in UserAgent**: Reduces AuthAgent RPC load by ~90% for active users.
4. **LRU cache eviction**: Prevents memory exhaustion from unbounded cache growth.
5. **No AdminAgent propagation**: TTL-based cache invalidation is sufficient for LMS (5 min max staleness acceptable).

## Long-Term Extensibility

| Feature | How It Fits |
|--------|-------------|
| Assessments | `UserAgent` adds `assessment_scores`. Submission = durable state update. Grading = fork `GradeFork`. |
| Attendance | `UserAgent` adds `attendance: Array[String]`. Mark = `mark_attendance(date)`. |
| Notifications | `schedule_future_call(send_reminder, in_24h)`. |
| Parent portal | New `ParentAgent` (durable). RPC to child `UserAgent`s. |
| Bulk operations | `@api.fork()` or child agent fan-out for parallel processing. |
| Analytics | Ephemeral `AnalyticsFork` reads SurrealDB, writes to warehouse. |
| Shared cache | Redis if Golem memory becomes limiting (scale-out phase). |
