# ADR 0003: Keep collected data for 7 days

Date: 2026-11-05 · Status: accepted

## Decision
- Phone and watch data (`app_usage_days`, `app_sessions`, `screen_events`,
  `health_samples`, `sleep_sessions`) is kept for the last 7 local days: today
  plus the previous 6, in each user's time zone.
- `PurgeStaleDataJob` runs hourly (Solid Queue recurring task) and deletes older rows.
- The upload API skips items that are already older than the window and reports
  them as `skipped`, so the phone's backfill never stores data that would be deleted.
- The window is `DATA_RETENTION_DAYS` (default 7). The dashboard always shows exactly
  that window; the 30-day view was removed.
- Accounts, devices, tokens and (later) planner data are not affected.

## Why
- The owner wants the database to hold only recent data.

## Consequences
- Week-over-week and monthly reports (M6.3), and correlations that need ≥ 10 days
  (sleep vs focus), are not possible at 7 days. Phase 5 indicators that use a 7-day
  window (sleep regularity, resting-HR trend) still work.
- Deleted data cannot be recovered; raising the window later only keeps data from then on.

## Revisit when
- Starting M6.3 or any feature that compares weeks. Options: raise
  `DATA_RETENTION_DAYS`, or keep small daily summaries (`daily_stats`) longer than raw rows.
