# ADR 0002: Build the Android collector before the planner

Date: 2026-11-04 · Status: accepted

## Decision
- Build the Rails ingest API (C1) and the Android collector app (C2–C6) before
  the planner (Phase 1) and focus features (Phase 2).
- The Android app's first job is a data node: it reads phone usage
  (`UsageStatsManager`) and watch data (Health Connect) and uploads it hourly.
  It does no analysis.
- The app signs in with email and password and receives a per-device bearer token.
- A dashboard with charts follows once data is flowing; the `chartkick` gem
  needs approval before it is added.

## Why
- Android keeps detailed usage events for only a few days, and Health Connect
  exposes only ~30 days before permission is granted. Starting early builds a
  baseline that later features (planned vs actual, distraction during sessions,
  sleep vs focus) can compare against.
- Seeing real Instagram/YouTube and sleep data is the owner's main motivation to
  keep using and building the app.

## Consequences
- Phase 3 is split: data upload moves to Phase C; check-in notifications stay in Phase 3.
- Phase 5 no longer includes reading Health Connect; it covers derived indicators only.
- The collector runs without planner data at first, so the first dashboard shows
  usage and body context only, not planned vs actual.

## Revisit when
- The collector misses data regularly on either phone (battery savers, permissions).
