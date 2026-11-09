# FocusOS roadmap

Beta: 2 users, both on Android. Web app on Railway; Kotlin Android app later.
Rule: don't start a phase until the previous one is used daily.

## Phase 0 – Foundation  ✅ this milestone
- [x] Rails 8.1 + PostgreSQL + Tailwind + Solid Queue (single database)
- [x] Sign-up (invite code), sign-in, password reset (email pending SMTP)
- [x] Settings: name, time zone, password; delete account with all data
- [x] Today page shell, installable web app (PWA manifest)
- [x] CLAUDE.md, CI (GitHub Actions), tests, RuboCop, Brakeman
- [x] Deploy to Railway
- [ ] Both users sign up

## Phase C – Android collector (pulled forward, see ADR 0002 and HANDOFF §6A)
- [x] C1 Rails ingest API: tokens, devices, upload endpoints incl. `check_ins`, Settings → Devices, `/phone` page
- [x] C2 Android project + sign-in (repo `focusos-android`)
- [x] C3 Permissions onboarding: Usage access, Health Connect, battery exemption
- [x] C4 Usage collector: daily per-app totals, app sessions, screen events
- [x] C5 Health Connect collector: heart rate, sleep, SpO₂, steps (+ HRV if present)
- [x] C6 Hourly sync worker, status screen, signed APK (friend install pending)
- [x] Dashboard with charts on collector data

## Phase 1 – Planner and checklist (web)
- [x] Subjects and topics (`/subjects`): add subjects, add topics under them, archive
- [x] Backlog board (`/board`): Backlog/Next/Today/Done lanes, drag-and-drop via SortableJS,
      moving a card into Done completes it, moving it out reopens it
- [ ] Day templates (fixed structure: wake, bed, meals, focus blocks) — next (P2)
- [ ] Plan timeline, Lock, plan API for the phone — next (P3)
- [ ] Morning carry-forward of unfinished tasks (user confirms)
- [ ] Recurring tasks
- [x] Each model scoped to the user, with a cross-user access test

## Phase 2 – Focus and check-ins (web)
- [ ] Focus timer (survives page reload), linked to a task
- [ ] End-of-session check-in: focus 1–5, task done / partial / not
- [ ] Progression ladder 10 → 20 → 25 minutes, promote/demote by completion rate
- [ ] Per-user reminder settings: active hours, interval 20/30 min, daily cap
- [ ] "Are you focused?" prompts: Yes / Drifting / Break
- [ ] Notifications via browser push and ntfy until the Android app exists
- **Gate:** both users use it daily for 2 weeks

## Phase 3 – Android app: interaction features (sign-in and usage upload are in Phase C)
- [ ] API for today, focus sessions and check-ins (reuses C1 token auth)
- [ ] Today view, start/stop session
- [ ] Native check-in notifications with action buttons (Firebase Cloud Messaging); watch mirrors them
- [ ] Distribute by APK or Play internal testing

## Phase 4 – Laptop tracking
- [ ] Sync script pushing ActivityWatch data to the server
- [ ] Per-user classification rules (YouTube, Instagram, study sites)
- [ ] Distraction time during planned study blocks

## Phase 5 – Watch data (Health Connect)
- Reading and uploading Health Connect data is done by the collector (C5)
- [ ] Indicators: sleep duration and regularity, wake-to-first-session delay,
      resting HR trend, sedentary streaks, readiness score
- [ ] Shown as "body context", never as a focus measurement

## Phase 6 – Reports and insights
- [ ] Daily summary: planned vs actual, focused minutes, distraction time, phone + laptop totals
- [ ] Weekly trends: best hours and days, subject split, check-in scores
- [ ] Correlations: sleep vs focus, late nights vs start time
- [ ] Rules engine and smarter nudges

## Ongoing
- Nightly database backups (Railway Postgres backups or `pg_dump`)
- Watch Railway usage and notification delivery
- Weekly feedback from beta users
