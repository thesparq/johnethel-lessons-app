# Plan

Build in this exact order. Each step must compile before moving to next.

## Hour 1 — Scaffold + Backend

- [x] Fix moon bin-deps EISDIR bug (move golem_sdk_tools from bin-deps to deps, override build commands in golem.yaml — see Sparq workaround)
- [x] `golem build` — confirm clean build with empty agents
- [x] Add components: api, user, admin, ui (manual scaffold due to golem new / moon.mod.json conflict)
- [x] Make ui component ephemeral (`#derive.agent("ephemeral")`)
- [x] Add file-server binding for ui (served from /dist, now /index.html after IFS workaround)
- [x] ApiAgent: HTTP endpoints with Bearer token extraction (placeholders)
  - GET /subjects
  - GET /subjects/:id/lessons
  - GET /lessons/:id
  - POST /lessons/:id/toggle
  - POST /admin/assign
- [x] `golem deploy` — deployed to local server
  - API: http://johnethel-lessons-app.localhost:9006
  - UI: http://johnethel-lessons-ui.localhost:9006
- [x] UserAgent: add SurrealDB HTTP client (wasi:http outgoing requests)
- [x] UserAgent: implement get_subjects() — query SurrealDB
- [x] UserAgent: implement get_lessons(subjectId) — query SurrealDB
- [x] UserAgent: implement get_lesson(lessonId) — query + filter student fields
- [x] UserAgent: implement toggle_lesson(lessonId) — teacher only, durable map
- [x] UserAgent: implement is_lesson_active(lessonId) — returns bool
- [x] AdminAgent: implement assign_teacher(teacherId, subjectId)
- [x] ApiAgent: JWT parsing (payload extraction, no sig verification)
- [x] ApiAgent: route all endpoints to correct UserAgent via cross-component RPC
- [x] golem.yaml: expose api component over HTTP, file-server for ui
- [x] `golem deploy` — confirm agents running

## Hour 2 — Frontend (mizchi/js SPA) ✓ Done
- [x] Scaffold frontend module in frontend/ with own moon.mod.json + moon.pkg.json
- [x] Add deps: mizchi/js, mizchi/signals (Luna doesn't compile with mr_moon_pkg)
- [x] Auth: login page with hardcoded JWT tokens (student/teacher); token stored in localStorage
- [x] Router: hash-based (#/ #/subject/:id #/lesson/:id #/admin #/logout)
- [x] Dashboard view: subject list cards, nav bar
- [x] Subject view: lessons grouped by week, back navigation
- [x] Lesson view: intro, content_sections, key_points, materials, objectives, conclusion
- [x] Teacher overlay: toggle button on lesson view (only visible for teacher token)
- [x] Admin view: assign teacher form
- [x] API client: fetch_json JS extern, JWT Bearer auth, async Promise handling
- [x] `moon build --target js` — clean build (0 errors)
- [x] Copy dist/ to ui/dist/ — 60KB JS bundle + index.html served by UI agent

## Hour 2 — Frontend

- [ ] Scaffold Rabbita app in frontend/ (clone rabbita-template)
- [ ] moon.mod.json: add mizchi/luna dep
- [ ] Auth module: OIDC login redirect, callback handler, token storage
- [ ] Router: /login /callback /dashboard /subject/:id /lesson/:id /admin
- [ ] Dashboard view: sidebar with subject list, main area greeting
- [ ] Subject view: lessons grouped by week, toggle badge for teachers
- [ ] Lesson view: render all student fields from content_sections
  - section header + body + sub_points
  - key_points list
  - materials list
  - inactive state: clean message card
- [ ] Teacher overlay: toggle button on lesson view
- [ ] API client module: fetch wrapper with JWT header
- [ ] `moon build --target js` — confirm clean build
- [ ] Copy dist/ to components/ui/frontend/dist/

## Hour 3 — Authentik + Wiring + Test

- [ ] Authentik: create application johnethel-lessons
- [ ] Authentik: create OAuth2/OIDC provider
- [ ] Authentik: create groups (students, teachers)
- [ ] Authentik: create 2 test students + 1 test teacher
- [ ] Authentik: assign users to groups
- [ ] Configure redirect URIs in Authentik provider
- [ ] Set AUTHENTIK_JWKS_URL env var in golem.yaml for api component
- [ ] Set SURREALDB_URL, SURREALDB_NS, SURREALDB_DB, SURREALDB_TOKEN in golem.yaml
- [ ] golem deploy — full deploy
- [ ] Test: student login → subject list → lesson list → lesson content
- [ ] Test: teacher login → toggle lesson off → student sees inactive message
- [ ] Test: teacher toggle back on → student sees content again
- [ ] Fix any issues

## Done when
Student can log in, browse subjects, open a lesson and read it.
Teacher can log in and toggle a lesson off/on.
