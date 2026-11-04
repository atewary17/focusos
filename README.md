# FocusOS

Plan your day, start small focus sessions, and see what you actually did.
Private beta for a few Android users.

**Current milestone:** foundation – sign-up and sign-in, settings (name, time
zone, password), delete account, and the Today page shell.

## Run locally (Mac)

Requirements: Ruby 3.3+, PostgreSQL running (Postgres.app or Homebrew).

```bash
bin/setup        # installs gems, creates databases
bin/dev          # http://localhost:3000
```

Sign up at http://localhost:3000/registration/new. Locally no invite code is needed.

Checks before every commit:

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

## Deploy to Railway

1. **Push to GitHub** (private repo):
   ```bash
   gh repo create focusos --private --source=. --push
   ```
   or create the repo on github.com and `git push`.

2. **Create the project:** Railway → New Project → Deploy from GitHub repo → pick `focusos`.
   Railway finds the `Dockerfile` and builds it.

3. **Add Postgres:** in the project, New → Database → PostgreSQL.

4. **Set variables** on the FocusOS service (Variables tab):

   | Variable | Value |
   | --- | --- |
   | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
   | `RAILS_MASTER_KEY` | contents of `config/master.key` (never commit this file) |
   | `SOLID_QUEUE_IN_PUMA` | `true` |
   | `SIGNUP_INVITE_CODE` | any phrase you share only with your friend |
   | `APP_HOST` | your Railway domain, e.g. `focusos-production.up.railway.app` |

5. **Public URL:** Settings → Networking → Generate Domain. Puma listens on the
   `PORT` Railway provides.

6. **Health check (optional):** Settings → Deploy → Healthcheck Path → `/up`.

7. **Deploy.** The Docker entrypoint runs `bin/rails db:prepare` on every boot,
   so migrations apply automatically.

On your Android phone, open the URL in Chrome → menu → **Add to Home screen**.

### Cost

Railway is not free long-term: new accounts get a one-time $5 trial credit, the
Free plan includes $1 of usage a month, and Hobby is $5/month including $5 of
usage. A Rails app plus Postgres for two users should fit within Hobby; check
the usage page after the first week.

### Known gaps in this milestone

- Password-reset emails need an SMTP provider (e.g. Brevo or Resend free tier),
  configured later. Until then, change passwords from Settings.

## Project docs

- `CLAUDE.md` – rules and commands for Claude Code
- `docs/plan.md` – roadmap and milestone checklist
- `docs/adr/` – architecture decisions
