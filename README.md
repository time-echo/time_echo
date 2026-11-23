# ⏳ TimeEcho — API Backend

TimeEcho is a secure, digital time-capsule platform designed to capture personal evolution, emotional shifts, and life predictions across time. This repository (`time_echo`) is the **API-only Ruby on Rails 8 backend**.

---

## ✨ Core Backend Features

- **Future Letters (Digital Capsules)**: Schedule encrypted letters for future delivery dates with timezone-aware release logic.
- **Active Record Encryption**: Protects sensitive letter titles, letter content, and life predictions/realities at rest using Rails Active Record Encryption (`encrypts :title`, `encrypts :content`, `encrypts :prediction`, `encrypts :reality`).
- **Digital Postage Stamps Catalog**: Manage and serve dynamic postage stamps organized by category (`small-things`, `places-i-inhabit`, `stored-thoughts`, `passage-of-time`), with vector SVG content, search by name/slug/category, and status filtering.
- **Personal Evolution Tracking**:
  - **Emotional Snapshots**: Record Happiness, Anxiety, and Motivation (1–10) when writing. Compute baseline shifts and emotional evolution upon delivery.
  - **Predictions vs. Reality**: Track future predictions across life categories (`city`, `salary`, `relationship`, `career`, `achievement`, `happiness`). Compare past forecasts with present outcomes upon unlock.
- **Passwordless Magic Link Authentication**: Cryptographically signed single-use access tokens delivered via Resend transactional email.
- **Background Job Scheduling (GoodJob)**: Database-backed Active Job queuing and cron execution for daily automated delivery dispatch (`0 0 * * *`) and hourly token cleanup (`0 * * * *`).
- **Error Tracking & Audit Logging**: Integrated with GlitchTip / Sentry (`sentry-rails`) and immutable `AuditLog` tracking across critical lifecycle mutations.
- **Interactive OpenAPI Documentation**: Swagger UI served directly at `/api-docs` via Rswag.

---

## 🏛️ System Architecture & Design Patterns

TimeEcho adopts a layered, highly decoupled API architecture:

1. **RESTful API Controllers (`app/controllers/api/v1/`)**:
   - Thin controllers inheriting from `Api::V1::BaseController < ActionController::API`.
   - Adhere strictly to RESTful actions (`index`, `show`, `create`, `update`, `destroy`).
   - Standardized exception mapping via `ErrorHandler` concern.
   - Standardized pagination via `Pagy` clamped to a maximum of 100 items per page.
2. **Form Objects (`app/forms/`)**:
   - Complex multi-model schema validation.
   - `LetterForm`: Atomically validates and persists `Letter`, `EmotionalSnapshot`, optional digital `Stamp` (via `stamp_slug` or `stamp_id`), and nested `Prediction` records in a single database transaction with IANA timezone conversion.
   - `MagicLinkForm`: Normalizes and validates email addresses for authentication.
3. **Service Objects (`app/services/`)**:
   - Encapsulate single-responsibility business workflows (`Letters::*`, `Auth::*`, `Analytics::*`, `Settings::*`).
   - Return clean `Result` objects unwrapped by `ResultHandler#unwrap!`.
4. **Query Objects (`app/queries/`)**:
   - `UserTimelineQuery`: Scopes active or archived letters for an authenticated user, paired with eager loading (`includes(:emotional_snapshot, :predictions, stamp: :stamp_category)`) in `LettersController#index` to eliminate $N+1$ queries.
   - `PendingLettersQuery`: Selects letters due for delivery using high-concurrency row locking (`FOR UPDATE SKIP LOCKED`) inside a transaction.
5. **Jbuilder JSON Serialization (`app/views/api/v1/`)**:
   - Formats API responses into standardized JSON envelopes (`data`, `meta`, and `error`) with `camelCase` keys.
6. **Policy Layer (`app/policies/`)**:
   - Fine-grained access control (`LetterPolicy` locks letters strictly to their creator's authenticated email).
7. **Background Jobs & Tasks (GoodJob)**:
   - `Letters::DispatchPendingJob`: Automated daily cron (`0 0 * * *`) dispatching individual `Letters::DeliverLetterJob` workers with exponential/polynomial retry backoff.
   - `CleanupExpiredTokensJob`: Automated hourly cron (`0 * * * *`) purging spent and expired tokens.
   - `rake letters:deliver`: Standalone CLI delivery trigger.

For detailed sequence diagrams, database schemas, and transactional boundary details:
👉 **[Backend Architecture & System Design (docs/architecture.md)](docs/architecture.md)**

---

## 📡 REST API Endpoints (`/api/v1`)

| Method   | Endpoint                                 | Description                                                             |
| -------- | ---------------------------------------- | ----------------------------------------------------------------------- |
| `GET`    | `/livez`                                 | Lightweight process liveness probe                                      |
| `GET`    | `/readyz`                                | Readiness healthcheck (verifies DB, migrations, GoodJob)                |
| `GET`    | `/api/v1/ping`                           | Timestamp and status diagnostic                                         |
| `GET`    | `/api-docs`                              | Interactive Swagger UI API documentation                                |
| `GET`    | `/api-docs/v1/swagger.yaml`              | OpenAPI 3.0.3 specification document                                    |
| `GET`    | `/api/v1/letters`                        | Paginated user capsule timeline (filters: `status`, `page`, `per_page`) |
| `POST`   | `/api/v1/letters`                        | Create a new capsule (supports `stamp_slug`, predictions, emotions)     |
| `GET`    | `/api/v1/letters/:id`                    | Fetch a single letter's details                                         |
| `DELETE` | `/api/v1/letters/:id`                    | Permanently delete an archived capsule                                  |
| `POST`   | `/api/v1/letters/:letter_id/predictions` | Update reality comparisons and reveal emotions                          |
| `POST`   | `/api/v1/letters/:id/archive`            | Move capsule to archive                                                 |
| `POST`   | `/api/v1/letters/:id/restore`            | Restore capsule from archive                                            |
| `GET`    | `/api/v1/stamps`                         | List stamp catalog (search `q`, `category`, `status`, pagination)       |
| `GET`    | `/api/v1/stamps/:slug`                   | Fetch a single stamp with raw vector SVG                                |
| `GET`    | `/api/v1/stamp_categories`               | List active stamp categories ordered by position                        |
| `POST`   | `/api/v1/sessions`                       | Request a passwordless magic login link                                 |
| `GET`    | `/api/v1/sessions/:token`                | Authenticate magic link token and start session                         |
| `GET`    | `/api/v1/sessions/me`                    | Fetch currently authenticated user session                              |
| `DELETE` | `/api/v1/sessions`                       | Destroy active session and invalidate cookie                            |
| `PATCH`  | `/api/v1/account`                        | Request email change confirmation                                       |
| `DELETE` | `/api/v1/account`                        | Purge entire user account and related records                           |
| `GET`    | `/api/v1/account/confirm_email`          | Confirm email change token                                              |

---

## 🛠️ Prerequisites & Stack

- **Ruby**: `4.0.1` (with Rails `8.1.x`)
- **Database**: PostgreSQL (`17-alpine`)
- **Queue Adapter**: GoodJob (database-backed Active Job)
- **Mailer**: Resend (`resend` gem) / Mailpit (local development)
- **Error Monitoring**: GlitchTip / Sentry (`sentry-ruby`, `sentry-rails`)
- **API Spec**: Rswag (OpenAPI 3.0.3)

---

## 🚀 Getting Started

### 1. Clone & Setup

```bash
git clone https://github.com/your-username/time_echo.git
cd time_echo
bundle install
```

### 2. Database Configuration

Ensure PostgreSQL is running locally. Set environment variables in `.env` if using custom credentials:

- `DATABASE_HOST` (default: `localhost`)
- `DATABASE_PORT` (default: `5432`)
- `DATABASE_USERNAME` (default: `postgres`)
- `DATABASE_PASSWORD` (default: `postgres`)

Initialize the database schema:

```bash
bin/rails db:prepare
```

### 3. Seed Demo Data

Populate the database with sample letters, predictions, emotional baselines, and stamp categories:

```bash
bin/rails db:seed
```

### 4. Run the Server

```bash
bin/rails server -p 3000
```

The API will be accessible at `http://localhost:3000`. Explore endpoints at `http://localhost:3000/api-docs`.

---

## 🐳 Running Supporting Services with Docker

TimeEcho includes a `docker-compose.yml` for local infrastructure and a `Dockerfile` for containerized deployments.

### Start Local Infrastructure

```bash
docker compose up -d
```

Services started:

- `db`: PostgreSQL 17 (port `5432`) — hosts `time_echo_development`
- `mailpit`: Local SMTP server (port `1025`) and web UI (`http://localhost:8025`)

---

## 🔧 Environment Variables

| Variable | Description | Default | Required |
| -------- | ----------- | ------- | -------- |
| `DATABASE_HOST` | PostgreSQL host | `localhost` | No |
| `DATABASE_PORT` | PostgreSQL port | `5432` | No |
| `DATABASE_USERNAME` | PostgreSQL username | `postgres` | No |
| `DATABASE_PASSWORD` | PostgreSQL password | `postgres` | No |
| `DATABASE_URL` | Full PostgreSQL connection URL (production) | — | Yes (production) |
| `DATABASE_PREPARED_STATEMENTS` | Enable prepared statements | `true` | No |
| `RAILS_MAX_THREADS` | Active Record connection pool / Puma threads | `5` | No |
| `WEB_CONCURRENCY` | Puma worker processes | `0` | No |
| `PORT` | Puma listen port | `3000` | No |
| `PIDFILE` | Puma PID file path | — | No |
| `APP_HOST` | Frontend application host (used in email links) | `localhost:3001` | No |
| `APP_PROTOCOL` | Frontend protocol for email links | `https` | No |
| `SMTP_HOST` | Local SMTP/Mailpit host | `localhost` | No |
| `RESEND_API_KEY` | Resend transactional email API key | — | No (dev uses Mailpit) |
| `CORS_ORIGINS` | Comma-separated allowed CORS origins | — | No |
| `SENTRY_DSN` | Sentry/GlitchTip DSN for error tracking | — | No |
| `GLITCHTIP_DSN` | GlitchTip DSN (alternative to SENTRY_DSN) | — | No |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Active Record encryption primary key | — | Yes (production) |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Active Record encryption deterministic key | — | Yes (production) |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Active Record encryption key derivation salt | — | Yes (production) |
| `ANALYTICS_ENABLED` | Enable PostHog analytics | `false` | No |
| `ANALYTICS_ENVIRONMENT` | Analytics environment name | `development` | No |
| `POSTHOG_HOST` | PostHog API host | `https://us.i.posthog.com` | No |
| `RAILS_LOG_LEVEL` | Rails log level | `info` | No |
| `GOOD_JOB_EXECUTION_MODE` | GoodJob execution mode (`async`/`sync`) | `async` | No |
| `CI` | Set to any value in CI to enable eager loading in tests | — | No |
| `RAILS_ENV` | Rails environment (`development`, `test`, `production`) | `development` | No |
| `BUNDLE_GEMFILE` | Path to Gemfile (set by `config/boot.rb`) | — | No |

Copy `.env.example` to `.env` and fill in values for your environment:

```bash
cp .env.example .env
```

Secrets such as encryption keys and API keys should be managed via Rails credentials in production:

```bash
bin/rails credentials:edit --environment production
```

---

## 🧪 Testing & Code Quality

TimeEcho has a comprehensive Minitest test suite covering controllers, models, services, forms, queries, policies, jobs, and mailers:

```bash
bundle exec rails test
```

Generate test coverage with SimpleCov:

```bash
COVERAGE=true bundle exec rails test
```

Run linting and static security analysis:

```bash
bundle exec rubocop -a
bundle exec brakeman --no-pager -q
bundle exec bundler-audit check
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
