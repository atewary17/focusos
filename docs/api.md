# FocusOS API v1 – contract

> **Collector endpoints (sign-in, devices, phone usage, health): `docs/HANDOFF.md`
> section 6A is authoritative** and replaces sections 2 and 4 below. This file
> is rewritten with `curl` examples as part of milestone C1.

Status: **design, not built.** Endpoints are implemented in the milestone named
next to each section (see `docs/HANDOFF.md` §6). Change this file in the same PR
when an endpoint's shape changes.

Clients:
- **Android app** (Kotlin) – daily use, phone usage, Health Connect data
- **ActivityWatch sync script** – laptop activity
- **Web dashboard** – server-rendered Rails pages, not this API (see §6)

---

## 1. Conventions

- Base path `/api/v1`, JSON request and response bodies only.
- Auth: `Authorization: Bearer <token>` on every endpoint except `POST /sessions`.
  Tokens are stored as SHA-256 digests (`api_tokens.token_digest`), shown once,
  revocable in Settings. Revoked or expired tokens get `401`.
- Every query is scoped to the token's user (`Current.user`). Another user's
  record returns `404`, never `403`.
- Timestamps: ISO 8601 UTC (`2026-11-04T09:31:02Z`). Dates: `YYYY-MM-DD` in the
  user's time zone.
- Uploads are **batches** and **idempotent**: each record has a natural unique
  key and is upserted, so re-sending is always safe. Responses:
  ```json
  { "accepted": 120, "cursor": "2026-11-04T09:40:00Z" }
  ```
- Limits: request body ≤ 1 MB (`413`), ≤ 1000 records per batch (`422`),
  uploads rate-limited per device (`429` with `Retry-After`).
- Errors:
  ```json
  { "error": { "code": "invalid_record", "message": "records[3].date is missing" } }
  ```
  | Status | `code` examples |
  | --- | --- |
  | 401 | `unauthorized`, `token_revoked` |
  | 404 | `not_found` |
  | 409 | `session_already_running` |
  | 413 | `payload_too_large` |
  | 422 | `invalid_record`, `too_many_records` |
  | 429 | `rate_limited` |
- Never log raw usage, activity or health payloads (filter them in
  `config/initializers/filter_parameter_logging.rb`).

---

## 2. Auth and devices (M3.1)

### `POST /api/v1/sessions`
Android login. Rate-limited like the web sign-in.
```json
// request
{ "email_address": "asha@example.com", "password": "…", "device_name": "Pixel 8" }
// 201
{ "token": "fo_live_…", "user": { "id": 1, "name": "Asha Rao", "time_zone": "Asia/Kolkata" } }
```
`401 unauthorized` on wrong credentials.

### `DELETE /api/v1/sessions/current`
Revokes the calling token. `204`.

### API tokens for scripts
Laptop scripts don't log in with a password. The user creates a token on the
web at **Settings → API tokens** (`/settings/api_tokens`), copies it once, and
puts it in the script's config.

### `POST /api/v1/devices`
Registers or updates a device. Unique by `(user, kind, name)`.
```json
// request
{ "kind": "android", "name": "Pixel 8", "platform_version": "15", "app_version": "0.3.0" }
// 201 (new) or 200 (existing)
{ "id": 3, "kind": "android", "name": "Pixel 8", "last_sync_at": null }
```

### `GET /api/v1/devices/:id/sync_state`
Last stored cursor per stream, so a reinstalled app or script can resume.
```json
{ "device_id": 5,
  "streams": {
    "aw-watcher-window":     "2026-11-04T09:40:00Z",
    "aw-watcher-afk":        "2026-11-04T09:40:00Z",
    "aw-watcher-web-chrome": "2026-11-04T09:38:12Z",
    "app_usage":             "2026-11-04",
    "health_samples":        "2026-11-04T06:00:00Z"
  } }
```

---

## 3. Android app – daily use (M3.1, M3.3)

### `GET /api/v1/today`
```json
{ "date": "2026-11-04",
  "ladder": { "level": 2, "session_minutes": 20, "sessions_per_day": 2, "completed_today": 1 },
  "running_session": null,
  "next_plan_item": { "id": 41, "starts_at": "2026-11-04T08:30:00Z", "minutes": 20,
                      "task": { "id": 77, "title": "Chapter 4 problems", "subject": "Physics" } },
  "tasks": [ { "id": 77, "title": "Chapter 4 problems", "status": "pending",
               "priority": 1, "planned_minutes": 40, "subject": "Physics" } ] }
```

### `PATCH /api/v1/tasks/:id`
`{ "status": "done" }` or `{ "status": "pending" }` (undo). Returns the task.

### `POST /api/v1/focus_sessions`
```json
{ "planned_minutes": 20, "task_id": 77, "plan_item_id": 41 }   // both ids optional
```
`201` with the session; `409 session_already_running` if one is running.
`source` is set to `android` from the token.

### `PATCH /api/v1/focus_sessions/:id`
One action per request:
```json
{ "action": "pause" }
{ "action": "resume" }
{ "action": "stop" }
{ "focus_rating": 4, "outcome": "done" }   // post-session check-in (M2.2)
```
Returns the session including server-computed `remaining_seconds`.

### `POST /api/v1/check_ins/:id/answer`
Called from notification action buttons without opening the app.
```json
{ "answer": "focused" }   // focused | drifting | on_break
```
`200`. Answering twice keeps the first answer.

### `POST /api/v1/push_tokens`
```json
{ "kind": "fcm", "token": "…", "device_id": 3 }
```
Upsert by token. `DELETE /api/v1/push_tokens/:token` on logout.

### `PATCH /api/v1/reminder_settings/quiet`
```json
{ "mode": "pause_1h" }        // pause_1h | done_for_today | resume
```

---

## 4. Android app – data uploads (M3.4, M5.1)

### `POST /api/v1/app_usage` – daily totals per app (hourly WorkManager job)
```json
{ "device_id": 3,
  "records": [
    { "package_name": "com.instagram.android", "app_label": "Instagram",
      "date": "2026-11-04", "foreground_seconds": 2140, "launches": 31,
      "first_used_at": "2026-11-04T03:12:00Z", "last_used_at": "2026-11-04T16:40:00Z" } ] }
```
- Unique key `(device_id, package_name, date)`; each upload **replaces** that
  day's totals, so the job re-sends today in full every hour.
- Backfill: on first run or after permission is granted, send the last 7 days.

### `POST /api/v1/usage_events` – optional intervals (for M4.3)
```json
{ "device_id": 3,
  "events": [ { "package_name": "com.google.android.youtube",
                "started_at": "2026-11-04T09:02:10Z", "ended_at": "2026-11-04T09:09:55Z" } ] }
```
Unique key `(device_id, package_name, started_at)`.

### `POST /api/v1/health/samples` – Health Connect (daily)
```json
{ "device_id": 3,
  "samples": [
    { "kind": "heart_rate", "recorded_at": "2026-11-04T02:10:00Z", "value": 58,
      "unit": "bpm", "source_package": "com.nothing.smartcenter" },
    { "kind": "steps", "recorded_at": "2026-11-04T04:00:00Z", "value": 812,
      "unit": "count", "source_package": "com.nothing.smartcenter" } ] }
```
`kind`: `heart_rate | spo2 | steps | resting_hr | hrv`.
Unique key `(user, kind, recorded_at, source_package)`.

### `POST /api/v1/health/sleep_sessions`
```json
{ "device_id": 3,
  "sessions": [
    { "started_at": "2026-11-03T17:40:00Z", "ended_at": "2026-11-04T01:05:00Z",
      "source_package": "com.nothing.smartcenter",
      "stages": [ { "stage": "deep", "start": "2026-11-03T18:10:00Z", "end": "2026-11-03T18:55:00Z" } ] } ] }
```
Unique key `(user, source_package, started_at)`.

---

## 5. ActivityWatch sync (M4.1)

ActivityWatch runs a local server on each laptop (`http://localhost:5600`). A
small script, scheduled by launchd (Mac) or Task Scheduler (Windows) every 10
minutes:

1. Reads its config: FocusOS URL, API token, `device_id`, and local cursors.
   On first run, it calls `POST /api/v1/devices` (`kind: laptop`) and, if the
   cursor file is missing, `GET /api/v1/devices/:id/sync_state`.
2. For each bucket (`aw-watcher-window_<host>`, `aw-watcher-afk_<host>`,
   `aw-watcher-web-chrome`), it reads
   `GET localhost:5600/api/0/buckets/<bucket>/events?start=<cursor>&limit=1000`.
3. Posts the events as-is in batches of up to 1000:

### `POST /api/v1/activity_events`
```json
{ "device_id": 5,
  "bucket": "aw-watcher-window",
  "events": [
    { "external_id": 81234, "timestamp": "2026-11-04T09:31:02Z", "duration": 184.2,
      "data": { "app": "Code", "title": "today_controller.rb" } } ] }
```
| `bucket` | expected `data` keys |
| --- | --- |
| `aw-watcher-window` | `app`, `title` |
| `aw-watcher-afk` | `status` (`afk` / `not-afk`) |
| `aw-watcher-web-chrome` | `url`, `title`, `audible`, `incognito` |

- The bucket name is sent without the `_<host>` suffix.
- Unique key `(device_id, bucket, external_id)`. The server keeps only the
  latest version of an event, because ActivityWatch extends the duration of the
  current event while it is still active.
- The server derives `domain` from `url`, marks window events overlapping AFK
  periods as `afk`, and applies `classification_rules` (M4.2).
- Incognito web events are stored with `url` and `title` removed.
- The script saves the returned `cursor` per bucket only after a `2xx`.
- Events older than 90 days are pruned by a nightly job.

Data flows only from the laptop up to the server; the server never connects to
the laptop.

---

## 6. Dashboard (M6.x)

Server-rendered Rails pages (Hotwire, charts), reading `daily_stats` (rebuilt
nightly by `DailyStatsRollupJob`) plus live data for today.

| Page | Shows |
| --- | --- |
| `/dashboard` | Today live: planned vs actual minutes, sessions, check-in focus %, distraction so far, last night's sleep |
| `/reports/daily/:date` | Timeline of plan vs sessions vs phone and laptop activity; top apps and sites; one suggestion |
| `/reports/weekly/:week` | Best-hours heatmap, best days, subject split, week-over-week change |
| `/reports/monthly/:month` | Trends; correlations (sleep vs focus, bedtime vs first start) shown only with ≥ 10 days of data |
| `/settings/categories`, `/settings/rules` | Classification rules, test a rule, reclassify history |
| `/settings/devices`, `/settings/api_tokens` | Connected devices, last sync time, create and revoke tokens |

JSON for the Android app, built from the same report objects as the pages:

### `GET /api/v1/reports/daily?date=2026-11-04`
```json
{ "date": "2026-11-04",
  "planned_minutes": 120, "focused_minutes": 85,
  "sessions": { "started": 4, "completed": 3 },
  "check_ins": { "asked": 6, "focused": 4 },
  "distraction_seconds": { "phone": 2700, "laptop": 900 },
  "feed_seconds": 2100,
  "first_session_at": "2026-11-04T04:12:00Z",
  "sleep_minutes": 412,
  "suggestion": "Most distraction happened 15:00–16:00. Plan a short session there." }
```

### `GET /api/v1/reports/weekly?start=2026-11-02`
Same fields summed per day (`days: [...]`), plus `best_hours` (hour → focus %)
and `subjects` (subject → focused minutes).

---

## 7. Build order

| Milestone | Endpoints |
| --- | --- |
| M3.1 | sessions, devices, today, tasks, focus_sessions, check_ins, push_tokens, reminder_settings/quiet |
| M3.4 | app_usage, usage_events, devices/:id/sync_state |
| M4.1 | activity_events, `/settings/api_tokens` page |
| M5.1 | health/samples, health/sleep_sessions |
| M6.x | dashboard pages, reports/daily, reports/weekly |
