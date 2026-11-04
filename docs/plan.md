# FocusOS roadmap

Beta: 2 users, both on Android. Web app on Railway; Kotlin Android app later.
Rule: don't start a phase until the previous one is used daily.

## Phase 0 – Foundation  ✅ this milestone
- [x] Rails 8.1 + PostgreSQL + Tailwind + Solid Queue (single database)
- [x] Sign-up (invite code), sign-in, password reset (email pending SMTP)
- [x] Settings: name, time zone, password; delete account with all data
- [x] Today page shell, installable web app (PWA manifest)
- [x] CLAUDE.md, CI (GitHub Actions), tests, RuboCop, Brakeman
- [ ] Deploy to Railway and sign up both users

## Phase 1 – Planner and checklist (web)
- [ ] Subjects and topics
- [ ] Tasks: priority, due date, planned minutes, status
- [ ] Day plan: place tasks into time slots
- [ ] Morning carry-forward of unfinished tasks (user confirms)
- [ ] Recurring tasks
- [ ] Each model scoped to the user, with a cross-user access test

## Phase 2 – Focus and check-ins (web)
- [ ] Focus timer (survives page reload), linked to a task
- [ ] End-of-session check-in: focus 1–5, task done / partial / not
- [ ] Progression ladder 10 → 20 → 25 minutes, promote/demote by completion rate
- [ ] Per-user reminder settings: active hours, interval 20/30 min, daily cap
- [ ] "Are you focused?" prompts: Yes / Drifting / Break
- [ ] Notifications via browser push and ntfy until the Android app exists
- **Gate:** both users use it daily for 2 weeks

## Phase 3 – Android app (Kotlin)
- [ ] Token API `/api/v1` in Rails (sign-in, check-ins, usage upload)
- [ ] Login screen, Today view, start/stop session
- [ ] Phone app usage via `UsageStatsManager`, uploaded hourly
- [ ] Native check-in notifications with action buttons (Firebase Cloud Messaging); watch mirrors them
- [ ] Distribute by APK or Play internal testing

## Phase 4 – Laptop tracking
- [ ] Sync script pushing ActivityWatch data to the server
- [ ] Per-user classification rules (YouTube, Instagram, study sites)
- [ ] Distraction time during planned study blocks

## Phase 5 – Watch data (Health Connect)
- [ ] Read heart rate, sleep, SpO₂, steps in the Android app
- [ ] Generic health samples table (accepts HRV from other watches)
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
