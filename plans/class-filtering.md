# Class-Level Filtering — Branch: feat/class-filtering

Secondary-only LMS. Filter lessons by `class_level`. Student class comes from Authentik metadata.

## Production Schema

`class_level` values: JSS_1, JSS_2, JSS_3, PRIMARY_1-5

Secondary classes only: JSS_1, JSS_2, JSS_3 (and future SS1, SS2, SS3)

## Implementation Plan

### 1. API Layer — Extract class_level from JWT
- [ ] `auth_user()` now returns `(user_id, role, class_level)` tuple
- [ ] Parse `class_level` from `principal.claims.groups` array
- [ ] Match known class codes: `JSS_1`, `JSS_2`, `JSS_3`, `SS1`, `SS2`, `SS3`
- [ ] Students get their class; teachers/admins get empty string (no filter)

### 2. UserAgent — Accept class_level filter
- [ ] `get_subjects(self, class_level)` — filter by class_level if set
- [ ] `get_lessons(self, subject, class_level)` — add class_level filter
- [ ] SQL: `WHERE class_level = 'JSS_3' AND subject = 'Agriculture' ...`

### 3. RPC Helpers — Pass class_level through
- [ ] Update `user_get_subjects`, `user_get_lessons` signatures

### 4. Frontend — Show class in nav
- [ ] Read class_level from JWT in `role_from_jwt` → return class
- [ ] Display class in nav header
- [ ] Teacher sees all classes; student sees only their class
