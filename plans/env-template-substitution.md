# Env Template Substitution — Branch: feat/env-template-substitution

Replace all hardcoded values in `golem.yaml` env vars with `{{ VAR_NAME }}` template substitution. At deploy time, Golem resolves these from the host OS environment variables.

## Changes

### golem.yaml — Replace hardcoded values with templates

| Component | Env Var | Before | After |
|-----------|---------|--------|-------|
| auth | AUTHENTIK_USERINFO_URL | `"https://auth.johnethel.school/application/o/userinfo/"` | `"{{ AUTHENTIK_USERINFO_URL }}"` |
| api | AUTHENTIK_URL | `"https://auth.johnethel.school"` | `"{{ AUTHENTIK_URL }}"` |
| api | AUTHENTIK_CLIENT_ID | `"rhca5hup..."` | `"{{ AUTHENTIK_CLIENT_ID }}"` |
| user | SURREALDB_URL | `"http://localhost:8000"` | `"{{ SURREALDB_URL }}"` |
| user | SURREALDB_NS | `"johnethel"` | `"{{ SURREALDB_NS }}"` |
| user | SURREALDB_DB | `"lessons"` | `"{{ SURREALDB_DB }}"` |
| user | SURREALDB_TOKEN | `"root"` | `"{{ SURREALDB_TOKEN }}"` |
| user | SURREALDB_USER | *(new)* | `"{{ SURREALDB_USER }}"` |

When `SURREALDB_USER` is set: uses `Basic base64(user:token)` auth.
When empty: uses `Bearer <token>` auth (for scope tokens).
| static | AUTHENTIK_URL | `"https://auth.johnethel.school"` | `"{{ AUTHENTIK_URL }}"` |
| static | AUTHENTIK_CLIENT_ID | `"rhca5hup..."` | `"{{ AUTHENTIK_CLIENT_ID }}"` |
| static | API_URL | `"http://johnethel-lessons-app.localhost:9006"` | `"{{ API_URL }}"` |

### New file: `.env.example`

Documents all required environment variables with example values for local development.

## Testing

```bash
# Source the env vars (create a .env file from .env.example first)
source .env

# Deploy (Golem resolves {{ VAR }} from current shell)
golem deploy -Y
```
