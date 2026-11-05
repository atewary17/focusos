# FocusOS API v1

The JSON API used by the FocusOS Android collector (`docs/HANDOFF.md` §6A).

Status:
- **Built (C1):** sign-in, device heartbeat, the five collector upload endpoints.
- **Planned:** `today`, focus sessions and check-ins (M3.1), ActivityWatch
  `activity_events` (M4.1), report JSON (M6.x). Their shapes are sketched at
  the end and will be finalised in those milestones.

Change this file in the same PR whenever an endpoint changes.

---

## Conventions

| | |
| --- | --- |
| Base URL | `https://focusos-production-7219.up.railway.app/api/v1` |
| Format | JSON request and response bodies (`Content-Type: application/json`) |
| Auth | `Authorization: Bearer <token>` on every endpoint except `POST /tokens` |
| Timestamps | ISO 8601 in UTC, e.g. `2026-11-04T09:31:02Z` |
| `date` fields | `YYYY-MM-DD`, the phone's local date |
| Body size | at most 1 MB (`413 payload_too_large`) |
| Batch size | at most 1000 `items` per request (`422`); the app sends ≤ 500 |
| Rate limit | 120 requests per hour per device, across all endpoints (`429`); sign-in: 10 per 3 minutes per IP |

**Uploads are idempotent.** Each item has a natural key (listed per endpoint).
Sending the same item again updates the stored row instead of adding a new one,
so the app can safely retry and re-send today's totals every hour. If one batch
contains the same key twice, the last one wins.

**Uploads are all-or-nothing.** If any (non-skipped) item is invalid, nothing in that request
is saved and the response lists the bad items by index.

**Scoping.** Every row is stored for the token's user and device. Another user's
data can never be read or changed through the API.

**Privacy.** Upload payloads (`items`, `permissions`, `summary`) are filtered
from request logs.

### Errors

```json
{ "error": { "code": "validation_failed", "message": "1 item(s) are invalid; nothing was saved.",
             "details": [ { "index": 1, "errors": [ "Foreground seconds must be in 0..86400" ] } ] } }
```

| Status | `code` | When |
| --- | --- | --- |
| 400 | `invalid_json` | Body is not valid JSON |
| 401 | `invalid_token` | Token missing, wrong, expired or revoked |
| 401 | `invalid_credentials` | Wrong email or password on sign-in |
| 403 | `device_required` | Token is not linked to a device (not possible for app sign-ins) |
| 413 | `payload_too_large` | Body over 1 MB |
| 422 | `validation_failed` | Missing `items`, too many items, or invalid items (`details`) |
| 429 | `rate_limited` | Too many requests; retry later with backoff |

### Trying it with curl

```bash
export FOCUSOS=https://focusos-production-7219.up.railway.app/api/v1
export TOKEN=fo_...   # from POST /tokens below; keep it private
```

---

## Sign in and out

### `POST /tokens`

Exchanges email and password for a token for this phone. The phone is identified
by `installation_id`, a UUID the app generates once and keeps. Signing in again
from the same phone updates the device and **replaces** its previous token.

```bash
curl -s -X POST $FOCUSOS/tokens -H 'Content-Type: application/json' -d '{
  "email_address": "you@example.com", "password": "your-password",
  "device": { "installation_id": "6f1c2a3e-1b2c-4d5e-8f90-123456789abc", "kind": "android",
              "name": "Pixel 7", "manufacturer": "Google", "model": "Pixel 7",
              "os_version": "15", "app_version": "0.1.0" } }'
```
`201`:
```json
{ "token": "fo_…", "user": { "name": "Asha Rao", "time_zone": "Asia/Kolkata" }, "device_id": 12 }
```
The token is shown only once; the server stores a SHA-256 digest.

### `DELETE /tokens/current`

Revokes the calling token (sign out). `204`.

```bash
curl -s -X DELETE $FOCUSOS/tokens/current -H "Authorization: Bearer $TOKEN" -w '%{http_code}\n'
```

Users can also sign a phone out on the web at **Settings → Devices**. That
deletes the phone's tokens and keeps the data it already uploaded.

---

## Device heartbeat

### `POST /devices/heartbeat`

Sent at the end of every sync. Updates the device's app version, permission
state and last sync time, shown on `/phone` and Settings → Devices.

```bash
curl -s -X POST $FOCUSOS/devices/heartbeat -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{
  "app_version": "0.1.0",
  "permissions": { "usage_access": true, "health_connect": ["heart_rate", "sleep", "spo2", "steps"], "battery_exempt": false },
  "summary": { "app_usage_days": 120, "app_sessions": 64, "health_samples": 310 } }'
```
`200`:
```json
{ "server_time": "2026-11-05T10:00:59Z", "min_app_version": "0.1.0" }
```
`min_app_version` comes from the `ANDROID_MIN_APP_VERSION` environment variable
(default `0.1.0`); the app should ask the user to update when it is older.

---

## Uploads

All five return `200 { "upserted": <rows written>, "skipped": <items older than the retention window> }`.

**Retention:** the server keeps only the last 7 local days of collected data
(`DATA_RETENTION_DAYS`; see `docs/adr/0003-seven-day-retention.md`). Older items in an
upload are skipped: not stored and not errors, so the app should still advance its
cursor past them. Rows that age out are deleted by an hourly job.

### `POST /app_usage_days` – per-app daily totals

Key: device + `package_name` + `date`. Re-sending a day replaces its numbers.

```bash
curl -s -X POST $FOCUSOS/app_usage_days -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{ "items": [
  { "date": "2026-11-05", "package_name": "com.instagram.android", "app_label": "Instagram",
    "foreground_seconds": 3720, "launches": 41,
    "first_used_at": "2026-11-05T02:10:00Z", "last_used_at": "2026-11-05T09:40:00Z" } ] }'
```
| Field | Rules |
| --- | --- |
| `date` | required; not more than 1 day ahead of the server's date |
| `package_name` | required, ≤ 255 chars |
| `app_label` | optional, ≤ 255 chars |
| `foreground_seconds` | integer 0–86400 |
| `launches` | integer ≥ 0 |
| `first_used_at`, `last_used_at` | optional; not in the future |

### `POST /app_sessions` – one stretch of an app in the foreground

Key: device + `package_name` + `started_at`. The server stores `duration_seconds`.

```bash
curl -s -X POST $FOCUSOS/app_sessions -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{ "items": [
  { "package_name": "com.google.android.youtube",
    "started_at": "2026-11-05T08:02:11Z", "ended_at": "2026-11-05T08:31:40Z" } ] }'
```
`ended_at` must not be before `started_at`; a session is at most 24 hours.

### `POST /screen_events` – screen on/off and unlocks

Key: device + `kind` + `occurred_at`. Unlocks are shown as pickups.

```bash
curl -s -X POST $FOCUSOS/screen_events -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{ "items": [
  { "kind": "unlock", "occurred_at": "2026-11-05T08:01:58Z" } ] }'
```
`kind` ∈ `screen_on`, `screen_off`, `unlock`.

### `POST /health_samples` – Health Connect readings

Key: user + `kind` + `recorded_at` + `source_package` (so the same reading
synced from two phones is stored once).

```bash
curl -s -X POST $FOCUSOS/health_samples -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{ "items": [
  { "kind": "heart_rate", "recorded_at": "2026-11-05T08:05:00Z", "value": 78, "unit": "bpm",
    "source_package": "com.nothing.smartcenter", "external_id": "hc-record-id" },
  { "kind": "steps", "recorded_at": "2026-11-05T07:00:00Z", "end_at": "2026-11-05T08:00:00Z",
    "value": 812, "unit": "count", "source_package": "com.nothing.smartcenter" } ] }'
```
| `kind` | Allowed `value` |
| --- | --- |
| `heart_rate`, `resting_hr` | 25–250 |
| `spo2` | 70–100 |
| `steps` | 0–100000 (use `end_at` for the interval) |
| `hrv_rmssd` | 0–500 |

`unit` and `source_package` are required; `end_at` must not be before `recorded_at`.

### `POST /sleep_sessions` – nights and naps

Key: user + `source_package` + `started_at`.

```bash
curl -s -X POST $FOCUSOS/sleep_sessions -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{ "items": [
  { "started_at": "2026-11-04T17:40:00Z", "ended_at": "2026-11-05T01:05:00Z",
    "source_package": "com.nothing.smartcenter", "external_id": "hc-sleep-1",
    "stages": [ { "stage": "light", "start": "2026-11-04T17:40:00Z", "end": "2026-11-04T18:10:00Z" },
                { "stage": "deep",  "start": "2026-11-04T18:10:00Z", "end": "2026-11-04T18:55:00Z" } ] } ] }'
```
`stage` ∈ `awake`, `sleeping`, `out_of_bed`, `light`, `deep`, `rem`, `awake_in_bed`, `unknown`.
`stages` may be empty.

All timestamps in uploads may be at most 5 minutes in the future (phone clock drift).

---

## Planned (not built yet)

These follow the same conventions and reuse the same tokens.

- **M3.1:** `GET /today`; `POST /focus_sessions`, `PATCH /focus_sessions/:id`
  (pause, resume, stop, post-session rating); `POST /check_ins/:id/answer`
  (`focused` / `drifting` / `on_break`); `POST /push_tokens` (FCM).
- **M4.1:** `POST /activity_events` from the ActivityWatch sync script, with
  tokens created on the web for laptops; key device + bucket + ActivityWatch event id.
- **M6.x:** `GET /reports/daily?date=…`, `GET /reports/weekly?start=…`, built from
  the same report objects as the web dashboard.
