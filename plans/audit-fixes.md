# Audit Fixes Plan — Branch: fix/audit-fixes

## Critical (C1-C4) — DONE

### C1 — PKCE State Parameter Validation (CSRF) — FRONTEND
**File:** `frontend/app.mbt`
- [x] Store `state` in sessionStorage before redirect to Authentik
- [x] On callback, extract `state` from URL, compare to stored value
- [x] Reject callback if state mismatch (redirect to `/login` with error)
- [x] Clear PKCE verifier from sessionStorage after exchange (success or failure)

### C2 — Teacher Fields Not Visible to Teachers — USER
**File:** `user/user_agent.mbt:342`
- [x] Wrap `filter_lesson_fields()` call in role check:
  - Students: strip teacher fields (current behavior)
  - Teachers/Admins: return full data with all fields

### C3 — Hardcoded SurrealDB Credential — USER
**File:** `user/user_agent.mbt:97,102`
- [x] Use `SURREALDB_TOKEN` env var value for Authorization header
- [x] Remove hardcoded `Basic cm9vdDpyb290`
- [x] Construct header from env var as `Basic root:<token>`

### C4 — Error Responses Cached at Full TTL — USER
**File:** `user/user_agent.mbt:282,322,351`
- [x] Do not cache error responses — return immediately without cache_set
- [x] In `get_subjects`, `get_lessons`, `get_lesson`: skip cache_set on Err

---

## High Priority (H1-H7) — DONE

### H1 — Toggle Errors Swallowed Indistinguishably — USER
**File:** `user/user_agent.mbt:361-405`
- [x] Return false on lesson-not-found, DB error, and invalid role
- [x] Added role check at start of toggle_lesson (defense-in-depth)
- [x] Valid lesson_id returns false for invalid/not-found instead of silently defaulting

### H2 — `&` Allowed in Subject Names — USER + API
**File:** `user/user_agent.mbt:258-270` and `api/jwt.mbt:18-26`
- [x] Removed `&` from `is_safe_subject_char` / `validate_subject_name`

### H3 — No 401/403 Handling in Frontend — FRONTEND
**File:** `frontend/app.mbt:186,200`
- [x] Added `on_auth_error` callback to `js_auth_fetch` and `js_auth_post`
- [x] On 401/403: dispatches `AuthExpired` → clears token, redirects to `/login`

### H4 — Hardcoded localhost URLs — FRONTEND + STATIC
**File:** `frontend/app.mbt:2` + `static/static_agent.mbt:84` + `golem.yaml`
- [x] Added `apiUrl` to `window.__CONFIG__` from env vars
- [x] `api_base` is now a function that reads from config
- [x] Added `API_URL` env var to static component in golem.yaml

### H5 — AdminAgent Toggle State in Memory — ADMIN
**File:** `admin/admin_agent.mbt`
- [x] Removed `lesson_toggle_state` from struct
- [x] Removed `toggle_lesson()` and `is_lesson_active()` methods
- [x] Removed dead `spawn_user()` method
- [x] Regenerated agent stubs

### H6 — OAuth2 URLs Not Percent-Encoded — FRONTEND
**File:** `frontend/app.mbt`
- [x] Added `js_url_encode` FFI using `encodeURIComponent()`
- [x] Encoded `client_id`, `redirect_uri`, `state` in authorize URL
- [x] Encoded `code`, `redirect_uri`, `client_id` in token exchange body

### H7 — Six `.unwrap()` Calls in HTTP Path — USER
**File:** `user/user_agent.mbt:114-131`
- [x] Attempted but reverted — WASI types don't match Option/Result pattern

---

## Medium Priority (M1-M10) — DONE

### M1 — Toggle Button Not Disabled During Loading — FRONTEND
**File:** `frontend/app.mbt`
- [x] Guard `ToggleLesson` in update against `model.loading` state

### M2 — `bytes_to_str_simple` Corrupts Non-ASCII UTF-8 — API
**File:** `api/api_agent.mbt:91-97`
- [x] Replaced with `@utf8.decode_lossy()`
- [x] Removed dead `bytes_to_str_simple` function

### M3 — No Input Validation on `assign_teacher` — API
**File:** `api/api_agent.mbt:218-225`
- [x] Added `validate_subject_name(subject)` check
- [x] Added empty `teacher_id` check

### M4 — XSS in config.js — STATIC
**File:** `static/static_agent.mbt:84`
- [x] Added `js_string_escape()` for proper backslash/quote escaping in config.js values

### M5 — Silent Data Swallowing on JSON Parse Failures — FRONTEND
**File:** `frontend/app.mbt`
- [x] `SubjectsLoaded`, `LessonsLoaded`, `LessonLoaded` check for empty results with non-empty body

### M6 — Role Precedence: Teacher Checked Before Admin — API
**File:** `api/api_agent.mbt` + `auth/auth_agent.mbt`
- [x] Changed order: `admin` checked before `teachers` in both `validate_principal_claims` and `parse_jwt`

### M7 + M8 — Cloud Config (retry + httpApi) — Golem Config
**File:** `golem.yaml`
- [x] Already configured by user with `vps` environment and `securityScheme`

### M9 — Callback Failure Refresh Loop — FRONTEND
**File:** `frontend/app.mbt`
- [x] CSRF failure, no-code, and LoginFailed all push `/login` URL (clears callback params from address bar)

### M10 — Missing Viewport Meta Tag — HTML
**File:** `ui/dist/index.html`
- [x] Added `<meta name="viewport" content="width=device-width, initial-scale=1.0">`

---

## Deferred (Low Priority) — DONE

- [x] Remove duplicate `js_redirect`, `js_form_post`, `js_current_url`, `js_get_query_param` non-JS stubs
- [x] Remove wildcard `_` from Principal match in `auth_user` (explicit variant matching)
- [x] Add `link rel=icon` favicon to index.html
- [x] Add `<noscript>` fallback to index.html
- [x] Add viewport meta tag (M10, committed earlier)

### Remaining (Phase 3 — Future)

- [ ] Dead code removal: ToggleFork, AuthAgent component
- [ ] 1MB response buffer upgrade
- [ ] Token refresh / silent re-authentication
- [ ] CSP headers
- [ ] Rename `jwt.mbt` → `validation.mbt`
- [ ] Structured logging
- [ ] LRU cache eviction
- [ ] Manual JSON string building → proper `@json` serialization
- [ ] `.to_owned()` cleanup in parse_jwt
- [ ] Max length enforcement on validated inputs
- [ ] `get_lesson` response shape consistency
- [ ] Static agent file descriptor cleanup
