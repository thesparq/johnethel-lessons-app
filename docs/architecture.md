# Architecture

## Components

```
components/
├── api/       HTTP entry point. Validates JWT. Routes to correct user agent.
├── user/      Durable per user. Student + teacher logic. Queries SurrealDB.
├── admin/     Durable singleton. Spawns user agents. Assigns teachers to subjects.
└── ui/        Ephemeral file-server. Serves Rabbita dist/.
```

## Agent types

**ApiAgent** — ephemeral, one per request
- Validates Authentik JWT
- Extracts userId + role from token claims
- Routes to UserAgent(userId) via Golem RPC
- Never touches SurrealDB directly

**UserAgent** — durable, one per user, identified by userId
- Student mode: queries SurrealDB for subjects, lesson lists, lesson content
  - Filters out teacher-only fields before returning
  - Checks TeacherAgent(subjectTeacherId).is_lesson_active(lessonId) before returning content
- Teacher mode: same as student + can call toggle_lesson(lessonId)
  - Holds toggle map in durable memory: Map[lessonId, Bool]
  - Knows which subjects they are assigned to (set by AdminAgent)
- First call: if agent doesn't exist yet, ApiAgent calls AdminAgent.spawn_user first

**AdminAgent** — durable, one globally
- spawn_user(userId, role, name) → creates UserAgent with correct config
- assign_teacher(teacherId, subjectId) → updates TeacherAgent's subject list
- list_users() → returns all spawned users

## Request flow

```
Frontend (JWT in Authorization header)
  → api component
  → validate JWT → extract userId, role
  → UserAgent(userId).handle_request(request)
     Student lesson request:
       → SurrealDB: fetch lesson by id
       → TeacherAgent(teacherForSubject).is_lesson_active(lessonId)
       → if active: return student fields only
       → if inactive: return { active: false }
     Teacher toggle:
       → TeacherAgent(userId).toggle_lesson(lessonId)
```

## API endpoints

```
GET  /subjects                    → list subjects for this user
GET  /subjects/:id/lessons        → list lessons for subject (weekly grouped)
GET  /lessons/:id                 → get lesson content
POST /lessons/:id/toggle          → teacher only, toggle active state
GET  /admin/users                 → admin only
POST /admin/assign                → assign teacher to subject
```

## SurrealDB queries

```
-- Subjects list (distinct from lesson_content table)
SELECT DISTINCT subject FROM lesson_content;

-- Lessons for subject (list view - no heavy content fields)
SELECT id, topic_title, week, term, subject FROM lesson_content
WHERE subject = $subject ORDER BY week;

-- Full lesson
SELECT * FROM lesson_content WHERE id = $id;
```

## Student-facing fields only
topic_title, subject, term, week, introduction, content_sections,
key_points, conclusion, materials, objectives, duration_mins

## Authentik setup
- New application: johnethel-lessons
- Provider: OAuth2/OIDC
- Redirect URI: http://localhost:3000/callback (dev), https://lessons.johnethel.school/callback (prod)
- Groups: students, teachers, admin
- Scopes: openid profile email groups
- JWT claim for role: groups claim maps to role in app

## Frontend routes (Rabbita)
```
/login          → redirect to Authentik
/callback       → handle OIDC callback, store token
/dashboard      → subject list sidebar + welcome
/subject/:id    → lesson list for subject grouped by week
/lesson/:id     → lesson content view
/admin          → admin panel (admin role only)
```
