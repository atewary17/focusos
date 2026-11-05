# FocusOS – notes for Claude Code

FocusOS helps a small group of students plan the day, start short focus sessions,
answer "are you focused?" check-ins, and compare what they planned with what they
actually did (phone, laptop and watch data). Private beta: 2 Android users.

Read `docs/plan.md` for the roadmap and `docs/HANDOFF.md` for decisions, data model and milestone criteria.
API endpoints (Phase 3+) follow the contract in `docs/api.md`. Work one milestone at a time.

## Stack
- Rails 8.1, Ruby 3.3, PostgreSQL, Hotwire (Turbo + Stimulus), importmap, Tailwind v4
- Rails built-in authentication (`app/controllers/concerns/authentication.rb`), plus sign-up in `RegistrationsController`
- Solid Queue in the primary database, run inside Puma (`SOLID_QUEUE_IN_PUMA=true`)
- Minitest + fixtures, RuboCop (rails-omakase), Brakeman
- Hosting: Railway (Dockerfile build, one Postgres service)
- Later: Kotlin Android app talking to `/api/v1` with token auth

## Commands
- `bin/dev` – run locally at http://localhost:3000
- `bin/rails test` – all tests (must pass before every commit)
- `bin/rubocop -a` then `bin/rubocop` – style
- `bin/brakeman --no-pager` – security scan
- `bin/rails db:migrate` – after adding a migration

## Rules
1. **Every record belongs to a user.** Always load data through `Current.user`
   (e.g. `Current.user.tasks.find(params[:id])`), never `Task.find(params[:id])`.
   Add a test proving one user cannot see another user's record.
2. **Time zones:** store UTC; requests run in the user's zone (`UserTimeZone`
   concern). Use `Time.zone.now` and `Date.current`, never `Time.now` or `Date.today`.
   `users.time_zone` holds IANA ids such as `Asia/Kolkata`.
3. **Tests first for logic** (models, services, jobs); integration tests for each
   controller action. Use the `sign_in(user)` helper in integration tests.
4. **No new gems without asking.** Prefer what Rails ships with.
5. **Small steps:** one milestone per branch and PR; plan before coding.
6. **Migrations** must be reversible and add `null: false` + indexes where sensible.
7. **Privacy:** activity and health data are sensitive. Never log raw usage or
   health payloads; deleting an account must delete all of a user's data
   (`dependent: :destroy` on every `has_many` from `User`; `:delete_all` for
   high-volume collected-data tables without callbacks). Add new upload keys
   to `config/initializers/filter_parameter_logging.rb`.
8. **Honest metrics:** watch data is "body context", never a focus or brain measurement.
9. Keep the UI simple: the Today page optimises for starting a session in one tap.

## API (`/api/v1`, contract in `docs/api.md`)
- Controllers inherit `Api::V1::BaseController` (`ActionController::API`, bearer
  tokens via `TokenAuthentication`, JSON errors, 1 MB body limit, rate limit).
- `Current.user` works for both cookie sessions and API tokens; `Current.device` is set for API requests.
- Upload endpoints use the `BatchUpload` concern: validate every item, then
  `upsert_all` on the model's `UPSERT_KEY`; all-or-nothing per request.
- Collected-data models include `CollectedData` and define `UPSERT_KEY` and `UPLOAD_ATTRIBUTES`.
- API request tests use `api_post(path, params, token:)` with tokens from `test/fixtures/api_tokens.yml`.

## Layout (planned modules)
- Planning: subjects, topics, tasks, day plans
- Focus: focus sessions, breaks, check-ins, progression ladder
- Nudges: reminder settings, message templates, notification log
- Tracking: phone/laptop activity imports, classification rules
- Health: Health Connect samples and derived indicators
- Insights: daily stats rollups, reports

## Environment variables (production)
`DATABASE_URL`, `SECRET_KEY_BASE`, `SOLID_QUEUE_IN_PUMA=true`, `APP_HOST`,
`SIGNUP_INVITE_CODE` (optional; restricts sign-up to people with the code),
`ANDROID_MIN_APP_VERSION` (optional; default `0.1.0`, returned by the device heartbeat).
