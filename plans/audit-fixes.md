# Audit Fixes Plan — Branch: fix/audit-fixes

## Critical (C1-C4)

### C1 — PKCE State Parameter Validation (CSRF) — FRONTEND
**File:** `frontend/app.mbt`
- [ ] Store `state` in sessionStorage before redirect to Authentik
- [ ] On callback, extract `state` from URL, compare to stored value
- [ ] Reject callback if state mismatch (redirect to `/login` with error)
- [ ] Clear PKCE verifier from sessionStorage after exchange (success or failure)

### C2 — Teacher Fields Not Visible to Teachers — USER
**File:** `user/user_agent.mbt:342`
- [ ] Wrap `filter_lesson_fields()` call in role check:
  - Students: strip teacher fields (current behavior)
  - Teachers/Admins: return full data with all fields
- [ ] Verify `lesson_steps` filter also applies only to students

### C3 — Hardcoded SurrealDB Credential — USER
**File:** `user/user_agent.mbt:97,102`
- [ ] Use `SURREALDB_TOKEN` env var value for Authorization header
- [ ] Remove hardcoded `Basic cm9vdDpyb290`
- [ ] Construct header from env var (bearer or basic depending on token format)

### C4 — Error Responses Cached at Full TTL — USER
**File:** `user/user_agent.mbt:282,322,351`
- [ ] Do not cache error responses, or use very short TTL (5-10 seconds)
- [ ] In `get_subjects`, `get_lessons`, `get_lesson`: skip cache_set on Err

---

## High Priority (H1-H7)

### H1 — Toggle Errors Swallowed Indistinguishably — USER
**File:** `user/user_agent.mbt:361-405`
- [ ] Return `Result[Bool, String]` or JSON with status info
- [ ] Distinguish: lesson not found, DB error, permission denied
- [ ] Add role check at start of toggle_lesson (defense-in-depth)

### H2 — `&` Allowed in Subject Names — USER
**File:** `user/user_agent.mbt:258-270` and `api/jwt.mbt:18-26`
- [ ] Remove `&` from `is_safe_subject_char` / `validate_subject_name`
- [ ] Or add proper SQL escaping before interpolation

### H3 — No 401/403 Handling in Frontend — FRONTEND
**File:** `frontend/app.mbt:186,200`
- [ ] Detect 401/403 responses in `js_auth_fetch` and `js_auth_post`
- [ ] On 401/403: clear token, redirect to `/login`
- [ ] Add specific error callback for auth failures vs. other errors

### H4 — Hardcoded localhost URLs — FRONTEND
**File:** `frontend/app.mbt:2,5`
- [ ] Read `api_base` from `window.__CONFIG__` (already configured for Authentik)
- [ ] Add `apiUrl` field to config.js/env vars

### H5 — AdminAgent Toggle State in Memory — ADMIN
**File:** `admin/admin_agent.mbt:6,45-56`
- [x] Already done — UserAgent handles toggle via SurrealDB
- [ ] Remove orphaned `lesson_toggle_state` map from AdminAgent
- [ ] Remove `toggle_lesson()` and `is_lesson_active()` methods

### H6 — OAuth2 URLs Not Percent-Encoded — FRONTEND
**File:** `frontend/app.mbt:358,635`
- [ ] Add `encodeURIComponent()` to redirect_uri in authorize URL
- [ ] Add `encodeURIComponent()` to code and redirect_uri in token exchange body

### H7 — Six `.unwrap()` Calls in HTTP Path — USER
**File:** `user/user_agent.mbt:114-131`
- [ ] Replace `.unwrap()` with proper `match` / `catch` error handling
- [ ] Return `Err(String)` instead of panicking

---

## Medium Priority (M1-M10)

### M1 — Toggle Button Not Disabled During Loading — FRONTEND
**File:** `frontend/app.mbt:842`
- [ ] Pass `model.loading` to `view_lesson`, disable button when loading
- [ ] Guard `ToggleLesson` in update against loading state

### M2 — `bytes_to_str_simple` Corrupts Non-ASCII UTF-8 — API
**File:** `api/api_agent.mbt:91-97`
- [ ] Replace with proper UTF-8 decoder (`String::from_utf8` or equivalent)

### M3 — No Input Validation on `assign_teacher` — API
**File:** `api/api_agent.mbt:218-225`
- [ ] Add `validate_subject_name(subject)` check
- [ ] Add `validate_teacher_id(teacher_id)` validator

### M4 — XSS in config.js — STATIC
**File:** `static/static_agent.mbt:84`
- [ ] Use JSON serialization for env var values in config.js generation

### M5 — Silent Data Swallowing on JSON Parse Failures — FRONTEND
**File:** `frontend/app.mbt:440,462,481`
- [ ] Surface parse errors in error field instead of returning empty arrays

### M6 — Role Precedence: Teacher Checked Before Admin — AUTH + API
**File:** `auth/auth_agent.mbt:107-108` and `api/api_agent.mbt:53-54`
- [ ] Check `admin` first, then `teachers`, then `students`

### M7 — Retry Policy Missing `cloud` — Golem Config
**File:** `golem.yaml:21-32`
- [ ] Add `cloud:` block with same retry policy

### M8 — Missing `cloud` httpApi Deployment — Golem Config
**File:** `golem.yaml:150-159`
- [ ] Add `cloud:` entry under `httpApi.deployments`

### M9 — Callback Failure Refresh Loop — FRONTEND
**File:** `frontend/app.mbt:409-421`
- [ ] On exchange failure, set route to `Login` instead of keeping `Callback`

### M10 — Missing Viewport Meta Tag — HTML
**File:** `ui/dist/index.html:4`
- [ ] Add `<meta name="viewport" content="width=device-width, initial-scale=1.0">`

---

## Deferred (Low Priority)

- [ ] Dead code removal: ToggleFork, AuthAgent component, AdminAgent.spawn_user
- [ ] Duplicate JS stubs cleanup
- [ ] 1MB response buffer upgrade
- [ ] Token refresh / silent re-authentication
- [ ] CSP, favicon, noscript
- [ ] Structured logging
- [ ] LRU cache eviction
