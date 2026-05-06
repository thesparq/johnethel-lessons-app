# Johnethel LMS — Architecture Review
## Proposed Design (SurrealDB + Per-User Cache)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AUTENTIK (Identity Provider + OAuth2 Authorization Server)                  │
│  - Central login dashboard for all school portals                            │
│  - Provides access_token (JWT) + id_token                                    │
│  - JWKS endpoint for signature verification                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ OAuth2 Authorization Code Flow
                                    │ (redirect to Authentik, callback with code,
                                    │  frontend exchanges code for tokens)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  FRONTEND — Rabbita SPA (served by static agent)                             │
│  - Stores access_token in localStorage                                       │
│  - Extracts user_id from JWT 'sub' claim                                     │
│  - API calls: GET /users/{user_id}/subjects                                  │
│               GET /users/{user_id}/subjects/{subject}/lessons                │
│               GET /users/{user_id}/lessons/{lesson_id}                       │
│               POST /users/{user_id}/lessons/{lesson_id}/toggle               │
│  - Header: Authorization: Bearer <access_token>                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP via Golem Gateway
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GOLEM HTTP GATEWAY                                                          │
│  Route: /users/{user_id}/... → UserAgent(user_id)::method()                  │
│  Creates UserAgent(user_id) lazily on first request                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  USERAGENT — Durable, Per-User Agent                                         │
│  Mount: /users/{user_id}                                                     │
│  ────────────────────────────────────────────────────────────────            │
│  State (durable, survives restarts):                                         │
│  - cache : Map[cache_key, (json_data, timestamp_ms)]                         │
│  - preferences : Map[String, Json]        (future: UI settings)              │
│  - progress : Map[String, Bool]           (future: lesson completion)        │
│  - assessment_scores : Map[String, Json]  (future)                           │
│  - attendance : Array[String]             (future: date strings)             │
│  ────────────────────────────────────────────────────────────────            │
│  Per-request flow:                                                           │
│  1. Extract Authorization header                                             │
│  2. RPC → AuthAgent.validate_token(token) → (user_id, role, email)           │
│  3. Verify: returned user_id == self.user_id (agent identity match)          │
│  4. If mismatch → return 401 Unauthorized                                    │
│  5. Execute business logic (cache check → fork QueryFork → return)           │
│  ────────────────────────────────────────────────────────────────            │
│  Cache strategy:                                                             │
│  - Cache key: "subjects", "lessons:{subject}", "lesson:{id}"                 │
│  - TTL: 5 minutes (300,000 ms) for lesson data                               │
│  - TTL: 10 minutes for subjects/lesson lists (rarely change)                 │
│  - On stale read: fork QueryFork → update cache → return fresh data          │
│  - On teacher toggle: invalidate own cache immediately, update DB            │
│  ────────────────────────────────────────────────────────────────            │
│  Endpoints:                                                                  │
│  - GET /users/{user_id}/subjects                                             │
│  - GET /users/{user_id}/subjects/{subject}/lessons                           │
│  - GET /users/{user_id}/lessons/{lesson_id}                                  │
│  - POST /users/{user_id}/lessons/{lesson_id}/toggle (teacher only)           │
│  - POST /users/{user_id}/assessments/{id}/submit (future)                    │
│  - POST /users/{user_id}/attendance (future)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ├──────────────────┬──────────────────┐
                                    │                  │                  │
                                    ▼                  ▼                  ▼
┌─────────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  QueryFork          │  │  AuthAgent       │  │  AdminAgent      │
│  (ephemeral)        │  │  (durable        │  │  (durable        │
│  ─────────────────   │  │   singleton)     │  │   singleton)     │
│  - Blocking HTTP    │  │  ─────────────── │  │  ─────────────── │
│    to SurrealDB     │  │  - jwks_cache    │  │  - subject_teacher│
│  - SELECT / UPDATE  │  │  - validated_at  │  │    assignments   │
│  - Returns JSON     │  │  - validate_jwt  │  │  - list_teachers │
│  - Dies             │  │  - refresh JWKS  │  │  - assign_teacher│
│                     │  │    every hour    │  │                  │
└─────────────────────┘  └──────────────────┘  └──────────────────┘
                                    │                  │
                                    ▼                  ▼
                           ┌──────────────────┐
                           │   SurrealDB      │
                           │  ─────────────── │
                           │  - lesson_content│
                           │    (with active) │
                           │  - future tables:│
                           │    assessments   │
                           │    attendance    │
                           └──────────────────┘
```

---

## 2. Component Responsibilities

### 2.1 Static Agent (Ephemeral)
**File**: `static/static_agent.mbt`
- Serves `index.html` and `johnethel-frontend.js` via IFS
- SPA catch-all: `/{*path}` returns `index.html` for unknown paths
- No state, no auth
- **Concern**: IFS read 64KB cap workaround in `read_file_bytes()`

### 2.2 AuthAgent (Durable Singleton)
**File**: `auth/auth_agent.mbt` *(NEW)*
- Caches Authentik JWKS in durable memory
- Validates JWT signatures and claims
- Returns `(user_id, role, email)` or error
- Refreshes JWKS cache every hour (self-scheduled)
- **Why durable**: JWKS cache must survive restarts to avoid refetching on every request

### 2.3 UserAgent (Durable Per-User)
**File**: `user/user_agent.mbt` *(REFACTORED)*
- Owns per-user state: cache, preferences, progress
- Validates every request via AuthAgent RPC
- Forks QueryFork for all blocking SurrealDB I/O
- **Why durable**: Cache, preferences, progress must survive restarts
- **Critical**: Never blocks on I/O directly — always forks QueryFork

### 2.4 QueryFork (Ephemeral)
**File**: `user/query_fork.mbt` *(NEW)*
- Stateless SurrealDB HTTP client
- Makes blocking WASI HTTP requests
- Dies after returning result
- **Why ephemeral**: If request hangs, only this instance dies. UserAgent stays responsive.

### 2.5 AdminAgent (Durable Singleton)
**File**: `admin/admin_agent.mbt` *(REDUCED SCOPE)*
- Owns `subject_teacher` assignments
- No toggle state (moved to SurrealDB)
- **Why durable**: Teacher assignments must survive restarts

---

## 3. Data Flow Analysis

### 3.1 Student Views Subjects (Happy Path)
```
Browser → GET /users/alice123/subjects (Authorization: Bearer <jwt>)
→ Gateway → UserAgent("alice123")::get_subjects(jwt)
  → AuthAgent.validate_token(jwt) → ("alice123", "student", "alice@school.edu")
  → Verify: "alice123" == self.user_id ✓
  → Check cache["subjects"]: miss or stale
    → Fork QueryFork("SELECT subject FROM lesson_content GROUP BY subject;")
    → QueryFork returns JSON → dies
  → Update cache["subjects"] = (json, now)
  → Return JSON to Browser
```
**Latency**: Auth RPC (~1ms) + cache miss → QueryFork (~100ms) = ~101ms first time. Subsequent: ~1ms (cache hit).

### 3.2 Student Views Lesson (Cache Hit)
```
Browser → GET /users/alice123/lessons/lesson_content:1
→ UserAgent checks cache["lesson:lesson_content:1"]
→ Fetched at t=0, TTL=5min, now t=2min → FRESH
→ Return cached JSON immediately (includes active: true/false)
```
**Latency**: ~1ms (auth RPC + cache lookup).

### 3.3 Teacher Toggles Lesson
```
Browser → POST /users/teacher456/lessons/lesson_content:1/toggle
→ UserAgent("teacher456")::toggle_lesson(jwt, "lesson_content:1")
  → AuthAgent.validate_token(jwt) → ("teacher456", "teacher", ...)
  → Verify role == "teacher" (or check AdminAgent assignment)
  → Fork QueryFork:
    1. "SELECT active FROM lesson_content:1" → true
    2. "UPDATE lesson_content:1 SET active = false"
  → Invalidate own cache["lesson:lesson_content:1"]
  → Return {"toggled": false, "active": false}
```
**Latency**: Auth RPC (~1ms) + QueryFork (~100ms) = ~101ms.

### 3.4 Student Views Lesson After Toggle (Other Student)
```
Browser → GET /users/bob789/lessons/lesson_content:1
→ UserAgent("bob789") checks cache
→ If cache is fresh (fetched before teacher toggled): returns stale "active": true
→ If cache is stale (TTL expired): forks QueryFork → gets "active": false → updates cache
→ Returns fresh data
```
**Max staleness**: 5 minutes (TTL).

---

## 4. Potential Issues & Mitigations

### 4.1 Cache Memory Growth (HIGH PRIORITY)
**Problem**: Each UserAgent caches lesson data. With 1000 students and 100 lessons, that's 1000 × 100 cache entries. Each entry is a large JSON string (~10KB). Total: ~1GB across all agents.

**Golem constraint**: Each agent has limited linear memory (configurable but not infinite).

**Mitigation**:
- Cache only what's needed (don't cache full lesson content for subjects list)
- Add cache size limit: LRU eviction when cache grows too large
- Use separate cache TTLs: subjects (10min), lesson lists (10min), lesson content (5min)
- Consider caching only lesson metadata, not full content sections

**Recommended cache structure**:
```moonbit
struct CacheEntry {
  data : String       // JSON string
  fetched_at : UInt64 // timestamp in ms
  ttl_ms : UInt64     // time-to-live
  size_bytes : UInt64 // for LRU eviction
}

struct UserAgent {
  user_id : String
  cache : Map[String, CacheEntry]
  // LRU tracking
  cache_total_bytes : UInt64
  max_cache_bytes : UInt64  // e.g., 5MB per user
}
```

### 4.2 AuthAgent Bottleneck (MEDIUM PRIORITY)
**Problem**: Every request validates JWT via RPC to AuthAgent. AuthAgent is a single durable agent processing requests sequentially. With 1000 concurrent users, AuthAgent becomes a bottleneck.

**Mitigation**:
- Cache validated tokens in UserAgent for short duration (e.g., 1 minute)
- If a token was validated 30 seconds ago, skip AuthAgent RPC
- Token cache key: token hash or prefix
- Reduces AuthAgent load by ~90% for active users

**UserAgent token cache**:
```moonbit
struct ValidatedToken {
  user_id : String
  role : String
  validated_at : UInt64
  ttl_ms : UInt64  // e.g., 60,000 ms (1 minute)
}

struct UserAgent {
  // ... other fields ...
  token_cache : Map[String, ValidatedToken]  // token_prefix → validation result
}
```

### 4.3 First Request for New UserAgent (LOW PRIORITY)
**Problem**: When UserAgent("newstudent") is created, it has cold cache. First request is slow (~100ms for DB query + auth).

**Mitigation**: This is expected and acceptable. Cache warms up on first use. No action needed.

### 4.4 SurrealDB Down (MEDIUM PRIORITY)
**Problem**: If SurrealDB is unreachable, QueryFork hangs. UserAgent returns error after timeout.

**Mitigation**:
- Add retry policy in `golem.yaml` for HTTP 502/503/504
- Return cached data even if stale (with warning header?)
- Set reasonable timeout on QueryFork (e.g., 5 seconds)
- Log error for monitoring

### 4.5 Teacher Assignment Check (MEDIUM PRIORITY)
**Problem**: When a teacher toggles a lesson, should we verify they're assigned to that subject? This requires AdminAgent RPC.

**Current design**: AdminAgent holds `subject_teacher` map.
**Decision**: On toggle, check `AdminAgent.get_teacher_for_subject(subject) == self.user_id`. If not assigned, return 403 Forbidden.

**Optimization**: Cache teacher assignments in UserAgent (teacher agents only). TTL: 1 hour.

### 4.6 JWT Validation Security (HIGH PRIORITY)
**Problem**: UserAgent validates token via AuthAgent, but what if token is revoked (user logged out, password changed)?

**Mitigation**:
- Short token lifetime (e.g., 15 minutes access_token, 1 hour refresh_token)
- Frontend refreshes token periodically
- For high-security scenarios, add token revocation list (complex, probably overkill for MVP)
- Accept the risk for MVP; implement refresh flow later

### 4.7 Cache Invalidation on Toggle (LOW PRIORITY)
**Problem**: When teacher toggles lesson, only teacher's own cache is invalidated. Other students see stale data until cache expires.

**Accepted**: This is by design. Max staleness = TTL (5 minutes). For an LMS, this is acceptable.

**Future enhancement**: If needed, implement push invalidation via AdminAgent broadcast. But keep it simple for now.

### 4.8 CORS Preflight Requests (MEDIUM PRIORITY)
**Problem**: Browser makes OPTIONS preflight before every POST/PUT/DELETE. UserAgent must handle OPTIONS.

**Current design**: ApiAgent had `#derive.mount_cors("*")`. UserAgent needs same.

**Mitigation**:
```moonbit
#derive.agent
#derive.mount("/users/{user_id}")
#derive.mount_cors("*")  // or specific origin
struct UserAgent { ... }
```

### 4.9 QueryFork SQL Injection (HIGH PRIORITY)
**Problem**: Current code constructs SQL by string concatenation: `"SELECT * FROM " + lesson_id + ";"`

**Risk**: If lesson_id contains malicious SQL, it could execute arbitrary commands.

**Mitigation**:
- Use SurrealDB parameterized queries
- Or validate lesson_id format strictly (e.g., `lesson_content:\d+` regex)
- Escape/quote identifiers

**Recommended**:
```moonbit
fn validate_lesson_id(id : String) -> Bool {
  // Must match pattern: table_name:record_id
  let parts = id.split(":").to_array()
  parts.length() == 2 && parts[0] == "lesson_content"
}
```

### 4.10 UserAgent Identity Spoofing (HIGH PRIORITY)
**Problem**: UserAgent validates that `returned_user_id == self.user_id`. But what if a malicious user crafts a JWT with `sub: "admin"`?

**Mitigation**:
- AuthAgent verifies JWT signature against Authentik JWKS
- Unsigned or invalid JWTs are rejected
- Only Authentik can issue valid JWTs
- As long as Authentik is secure, spoofing is impossible

### 4.11 Memory Leak in QueryFork (LOW PRIORITY)
**Problem**: QueryFork is ephemeral and dies after execution. But what if `blocking_read(1048576UL)` reads huge response? Memory usage spikes.

**Mitigation**:
- Limit read size (1MB is fine for lesson data)
- QueryFork dies after execution, so memory is freed
- No leak possible

### 4.12 Cache Key Collisions (LOW PRIORITY)
**Problem**: If cache key is just `"lesson:" + id`, what if a future feature adds a different "lesson" namespace?

**Mitigation**:
- Use structured cache keys: `"content:" + id`, `"list:" + subject`, `"subjects"`
- Or use enum for cache key type

---

## 5. Golem-Specific Constraints & Compliance

### 5.1 Sequential Execution
**Constraint**: Each agent processes one invocation at a time.
**Impact**: UserAgent("alice") handles one request at a time. If Alice opens 5 tabs, requests queue up.
**Mitigation**: Each request is fast (cache hit = ~1ms, cache miss = ~100ms). Acceptable for human interaction.

### 5.2 Durable Agent State
**Constraint**: Agent state is persisted in oplog. Large state = slow recovery.
**Impact**: If UserAgent caches 100 lessons at 10KB each = 1MB state. With 1000 users = 1GB total oplog.
**Mitigation**: Cache size limits, LRU eviction. Consider shorter TTLs for large data.

### 5.3 Ephemeral Agent Lifecycle
**Constraint**: Ephemeral agents get fresh instance per invocation.
**Impact**: QueryFork always starts from `new()`. No connection reuse.
**Mitigation**: This is fine. Each QueryFork makes one HTTP request and dies.

### 5.4 WASI HTTP Blocking
**Constraint**: `pollable.block()` and `stream.blocking_read()` block the agent.
**Impact**: If QueryFork hangs, it blocks until timeout (or forever if no timeout).
**Mitigation**: QueryFork is ephemeral. If it hangs, it dies. But UserAgent waits for the fork to complete.
**Issue**: If QueryFork hangs, UserAgent's `invoke_and_await("execute", ...)` also hangs.
**Solution**: Need timeout mechanism. Golem doesn't have built-in RPC timeouts. Workaround: use `with_reservation` or accept the risk. For MVP, accept.

### 5.5 String Encoding
**Constraint**: MoonBit strings are UTF-16. SurrealDB expects UTF-8.
**Impact**: Our `str_to_bytes` function converts char-by-char, which may not handle multi-byte UTF-8 correctly.
**Mitigation**: Use proper UTF-8 encoding. Check if MoonBit SDK has built-in UTF-8 encoder.

---

## 6. Long-Term Scalability

### 6.1 Adding Assessments
```moonbit
// New table in SurrealDB: assessments
// UserAgent adds:
assessment_submissions : Map[String, Json]

// New endpoint:
#derive.endpoint(post="/assessments/{assessment_id}/submit")
pub fn UserAgent::submit_assessment(self : Self, assessment_id : String, answers : Json) -> Json { ... }
```

### 6.2 Adding Attendance
```moonbit
// UserAgent adds:
attendance : Array[String]  // ISO date strings

// New endpoint:
#derive.endpoint(post="/attendance")
pub fn UserAgent::mark_attendance(self : Self, date : String) -> Bool { ... }
```

### 6.3 Adding Notifications
```moonbit
// Use Golem's schedule_future_call
#derive.endpoint(post="/reminders")
pub fn UserAgent::schedule_reminder(self : Self, lesson_id : String, reminder_at : UInt64) -> Unit {
  // Schedule a future call to send_notification(lesson_id)
}
```

### 6.4 Adding Parent Portal
```moonbit
// New component: parent/
// ParentAgent (durable per-parent)
// Links to child UserAgents via RPC
```

### 6.5 Cache Optimization for Scale
- Shorter TTL for frequently changing data (toggle: 5min)
- Longer TTL for static data (subjects: 1 hour)
- LRU eviction when cache grows too large
- Consider shared cache (Redis) if Golem memory becomes limiting factor

---

## 7. Security Review

| Threat | Mitigation | Status |
|--------|-----------|--------|
| JWT spoofing | AuthAgent verifies signature against JWKS | ✅ Secure |
| UserAgent identity mismatch | Verify `returned_user_id == self.user_id` | ✅ Secure |
| Student toggles lesson | Role check: `role == "teacher"` | ✅ Secure |
| SQL injection | Validate lesson_id format, use parameterized queries | ⚠️ NEEDS FIX |
| CORS attacks | `mount_cors("*")` for dev, restrict in prod | ⚠️ CONFIG NEEDED |
| Token replay | Short token lifetime (15 min) | ⚠️ CONFIG NEEDED |
| Cache poisoning | Cache is per-user, only stores own query results | ✅ Secure |
| Information leakage | Teacher-only fields filtered before caching | ✅ Secure |

---

## 8. Failure Modes & Recovery

| Scenario | Behavior | Recovery |
|----------|----------|----------|
| SurrealDB down | QueryFork hangs → UserAgent timeout → returns error | Auto-retry via retry policy. Return stale cache if available. |
| AuthAgent down | JWT validation fails → all requests 401 | AuthAgent is durable, survives restarts. If corrupted, delete and recreate. |
| UserAgent deleted | Next request recreates UserAgent with empty cache | Cache rebuilt on demand. Durable state (progress, attendance) lost unless backed up. |
| Golem server restart | All agents resume from oplog | Durable state restored. Ephemeral agents recreated. |
| Authentik down | JWT validation fails → 401 | Users can't log in. Existing valid tokens work until expiry. |
| Frontend bug | Malformed requests → 400 Bad Request | Log error, return helpful message. |

---

## 9. Action Items Before Implementation

### Critical (Must Fix)
1. **SQL injection prevention**: Add lesson_id validation, use parameterized queries
2. **Token caching in UserAgent**: Cache validated tokens for 1 minute to reduce AuthAgent load
3. **Cache size limits**: Add LRU eviction to prevent memory exhaustion
4. **CORS configuration**: Add `mount_cors` to UserAgent

### Important (Should Fix)
5. **Retry policies in golem.yaml**: Add HTTP transient retry policy
6. **Teacher assignment validation**: Check AdminAgent on toggle
7. **UTF-8 encoding**: Fix `str_to_bytes` to handle multi-byte characters
8. **Cache key structure**: Use typed cache keys (enum or prefix)

### Nice to Have (Can Defer)
9. **Metrics/logging**: Add structured logging for debugging
10. **Cache warm-up**: Pre-fetch popular lessons on agent creation
11. **Token refresh flow**: Frontend periodically refreshes access_token
12. **Shared cache**: Redis for cross-agent cache (if scale requires)

---

## 10. Verdict

**This architecture is sound and scalable.** The key decisions are:
- ✅ Direct UserAgent HTTP routing (matches your vision)
- ✅ Toggle in SurrealDB (simple, one source of truth)
- ✅ Per-user caching (fast reads, natural TTL invalidation)
- ✅ Ephemeral QueryFork (isolates blocking I/O)
- ✅ AuthAgent singleton (centralized JWT validation)

**The main risks are manageable:**
- Cache memory growth → LRU eviction
- AuthAgent bottleneck → token caching in UserAgent
- SQL injection → input validation

**Ready to implement.**
