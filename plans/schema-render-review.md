# Schema Rendering & Auth Fix — Branch: fix/schema-render-review

## Problem

1. **SURREALDB_URL** has `/version` suffix — breaks SQL endpoint (should be just the base URL)
2. **SurrealDB Cloud auth** uses JWT tokens (not Basic auth like local) — need signin + token caching
3. **Student field filtering** doesn't match production schema — missing MCQ/theoretical question filters

## Production Schema (`lesson_content`)

### Teacher-only fields (strip for students)
| Field | Type | Content |
|-------|------|---------|
| `teacher_tips` | string | Teaching guidance |
| `formative_assessment` | string | Exit tickets, class checks |
| `summative_assessment` | string | Test/quiz content |
| `remediation` | string | Remediation strategies |
| `mcq_questions[].correct_answer` | string | Answer key |
| `mcq_questions[].explanation` | string | Answer explanation |
| `theoretical_questions[].model_answer` | string | Model answer |
| `theoretical_questions[].marking_scheme` | string | Marking guide |
| `lesson_steps[].teacher_actions` | string | Teacher instructions |
| `lesson_steps[].assessment` | string | Assessment notes |

### Student field transformations
- **mcq_questions**: Return random 5, strip `correct_answer` + `explanation`
- **theoretical_questions**: Return random 5, strip `model_answer` + `marking_scheme`
- **lesson_steps**: Strip `teacher_actions` + `assessment` (already done)

## Changes

### 1. Fix SURREALDB_URL in .env.example
- [ ] Remove `/version` suffix: `https://vivid-island-te-...cloud`

### 2. Fix SurrealDB Cloud Auth (user_agent.mbt)
- [ ] Add `surrealdb_signin()` — POST to `/signin` with NS/DB/user/pass
- [ ] Cache JWT token with refresh (token expires in ~1hr)
- [ ] Use `Bearer <token>` for queries
- [ ] Fall back to Basic auth if signin fails (local dev compat)

### 3. Update filter_lesson_fields + add question filters (user_agent.mbt)
- [ ] Strip teacher-only fields (already done)
- [ ] Add `filter_mcq_questions(json, random_count=5)` — removes answers, randomly selects
- [ ] Add `filter_theoretical_questions(json, random_count=5)` — removes model_answer/marking_scheme, randomly selects
- [ ] Apply random selection to `mcq_questions` and `theoretical_questions` in student path
