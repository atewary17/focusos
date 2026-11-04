# ADR 0001: Stack and hosting for the beta

Date: 2026-11-04 · Status: accepted

## Decision
- One Rails 8.1 monolith (Hotwire, Tailwind) with PostgreSQL.
- Solid Queue runs inside Puma and stores its tables in the primary database.
  Solid Cache and Solid Cable are removed: in-memory cache and the async Action
  Cable adapter are enough for a single Railway service.
- Hosted on Railway from the repo's Dockerfile, with one Postgres service.
  Settings live in the Railway dashboard rather than `railway.toml`, because
  Railway's file-based config is deprecated from 2026-12-01.
- Sign-up is open in code but gated by `SIGNUP_INVITE_CODE` in production.
- A Kotlin Android app will be added in Phase 3 and talk to a token API.

## Why
- The owner knows Rails and PostgreSQL; one deployable keeps cost and upkeep low.
- Two beta users do not need separate cache, cable or queue databases.

## Revisit when
- More than one app replica is needed (switch Action Cable to Solid Cable or Redis).
- Railway usage regularly exceeds the Hobby plan's included $5.
