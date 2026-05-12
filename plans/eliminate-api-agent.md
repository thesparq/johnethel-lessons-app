# Eliminate ApiAgent — Branch: refactor/eliminate-api-agent

## Goal

Eliminate the ApiAgent component. Move HTTP routing + JWT parsing directly into UserAgent.
This reduces RPC hops from 2 to 1 per request and simplifies the architecture.

## Current Architecture

```
Browser → ApiAgent(ephemeral) ──RPC──→ UserAgent(durable) ──RPC──→ QueryFork → SurrealDB
            │                                │
            ├─ JWT parsing                   ├─ Cache
            ├─ Group enforcement             └─ DB queries
            └─ Input validation
```

## Target Architecture

```
Browser → UserAgent(durable, HTTP mount, per-user) ──RPC──→ QueryFork → SurrealDB
            │
            ├─ JWT parsing
            ├─ Group enforcement
            ├─ Input validation
            ├─ Cache
            └─ DB queries
```

## Key Insight

Golem 1.5.1 supports `#derive.mount_auth(true)` on durable agents with Principal in
the constructor. The Principal determines the agent identity:
- `Principal::Oidc(sub: "alice")` → UserAgent for alice
- `Principal::Oidc(sub: "bob")` → UserAgent for bob  
- `Principal::Anonymous` → public endpoints (/config)

This gives us per-user durable agents with TTL caching and no extra RPC hops.

## Changes

### 1. user/user_agent.mbt — Add HTTP mount + JWT parsing
- [ ] Move JWT parsing from api/api_agent.mbt
- [ ] Add `#derive.mount("/")`, `#derive.mount_cors("*")`, `#derive.mount_auth(true)`
- [ ] Change constructor to `fn new(principal: @common.Principal)`
- [ ] Add helper to extract user_id, role, class_level from Principal
- [ ] Add /config endpoint (public, no auth)
- [ ] Add /classes, /subjects, /terms, /lessons, /toggle, /admin/assign endpoints
- [ ] Keep caching, SQL queries, student filtering as-is

### 2. api/ — Deprecate ApiAgent
- [ ] Comment out or remove HTTP endpoints from api_agent.mbt
- [ ] Keep ToggleFork for provision config compatibility (if needed)
- [ ] Remove RPC helpers (no longer needed)

### 3. golem.yaml — Route HTTP to UserAgent
- [ ] Change httpApi deployment from ApiAgent to UserAgent
- [ ] Add auth env vars to user component

### 4. Frontend — None
- [ ] No changes needed (same endpoints, same URLs)
