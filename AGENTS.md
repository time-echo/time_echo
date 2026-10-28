# AI Agent Guidelines & Constraints — TimeEcho

Welcome to **TimeEcho**! As an AI coding assistant, you must strictly adhere to the following rules, constraints, and patterns when working on this codebase. These guidelines are designed to ensure database safety, maintain visual consistency, preserve architectural integrity, and keep the code clean.

---

## 🚫 1. Execution Restrictions (Migrations, Server, Docker)

- **No Database Migrations**: AI agents and automated assistants must **NEVER** run database migrations (such as `bin/rails db:migrate`, `db:rollback`, or `bundle exec rake db:migrate`). All migrations must be run manually by the developer.
- **No Server Execution**: AI agents must **NEVER** start or run the local Rails server (such as `rails server`, `bin/rails s`, or `bin/dev`).
- **No Docker Control**: AI agents must **NEVER** execute Docker or docker-compose commands (such as `docker ps`, `docker compose up`, or docker start/stop/prune actions).

---

## 🎨 2. Design System & Premium Aesthetics (Postal & Archival Standard)

TimeEcho enforces a tactile, nostalgic, and secure visual identity built on top of **Tailwind CSS v4** and **DaisyUI v5**. The application consciously rejects generic corporate SaaS tropes in favor of an **archival, epistolary, and postal aesthetic**. For full specification, read **[`docs/ui-ux.md`](docs/ui-ux.md)**.

### A. Tripartite Typography Hierarchy
- **Editorial Serif (`font-serif-editorial`)**: Use **Fraunces** (`font-serif-editorial`) for page headers, capsule headlines, reveal screens, and literary reading passages.
- **Archival & Epistolary (`font-letter`)**: Use **Courier Prime** (`font-letter`) for letter compositions, docket numbers (`№ TE-00042`), postmark cancellation stamps, dates, and archival counters.
- **Functional UI (`font-ui` / `font-sans-ui`)**: Use **IBM Plex Sans** / **Work Sans** (`font-ui`) for buttons, form labels, operational statuses, navigation, and badges.

### B. Physical Postal & Archival Palette
- **Wax Seal Carmine Red (Primary)**: `#8E2818` (light mode), `#6A1E12` (hover/active), `#D14930` (dark mode). Strictly avoid purple or violet (`oklch(... 290)`).
- **Postmark Ink Indigo (Secondary/Accent)**: `#2C485E` (light mode), `#77A3C4` (dark mode). Used for cancellation stamps, ink lines, and timeline markers.
- **Archival Manila & Parchment (Surfaces)**: `#FAF9F5` (light paper sheet), `#16181D` (dark paper sheet), `#EFECE3` (manila dossier folder), `#1C2028` (dark dossier folder).
- **Archival Crease Borders**: `#D8D2C2` (light borders), `#2D3340` (dark borders). Avoid pure black borders or harsh drop shadows.

### C. Core Postal Components
- **Paper Sheet (`.paper-sheet`)**: Tactile paper canvas simulating real stationery for letters, forms, and cards.
- **Archival Folder (`.archival-folder`)**: Dossier-style layout with folder tabs and docket reference headers.
- **Postmark Cancellation Stamp (`.postmark-stamp`)**: Ink-dashed stamps with slight hand-stamped rotation (`-1.5deg` to `1.5deg`) for statuses.
- **Wax Seal (`.wax-seal`)**: Embossed carmine wax seal badge. Includes physical fracture animations (`seal-crack-left`, `seal-crack-right`) during capsule reveal.
- **Ruled Letter Canvas (`.lined-paper-canvas`)**: Lined paper guide for writing letters.
- **Reality Verification Ledger (`Expediente de Realidad`)**: Two-column layout in `letters/show` for retrospectively comparing past predictions against reality.

### D. Explicit Anti-Patterns (Strictly Avoid)
- ❌ **No Identical Rounded Cards**: Do not wrap every element in uniform `rounded-2xl p-6 shadow-md` cards. Use `.paper-sheet`, `.archival-folder`, or ledger rows with structural variety.
- ❌ **No Icons in Pastel Circles**: Never place generic library icons inside soft colored circular background badges.
- ❌ **No Purple / Violet Buttons**: Never use purple or violet hues (`bg-purple-600`, `oklch(... 290)`). Use Wax Seal Carmine (`#8E2818`).
- ❌ **No Flat Beige Clichés**: Do not rely on flat beige backgrounds without material texture, borders (`#D8D2C2`), and ink typography.
- ❌ **No Eyebrow Dot Dividers**: Avoid uppercase marketing tropes like `CÁPSULA · PENDIENTE →`. Use postal stamps or docket numbers.
- ❌ **No Emojis as UI Icons**: Do not use emojis (⏳, 🔒, 📝) as UI control icons. Use clean SVG strokes or typographic symbols (`№`, `§`).

---

## 🏛️ 3. Thin Controllers & Service Objects

TimeEcho enforces a strict separation of concerns following the **"Thin Controllers, Single-Responsibility Services"** standard.

- **No Database Operations in Controllers**: Controller actions must not contain direct multi-table transactions, format validations, token creations, mailer dispatch loops, or raw SQL.
- **Service Objects**: Complex business logic must be isolated in service objects under `app/services/`.
- **RESTful Actions Only**: Controllers must stick to the seven standard RESTful actions (`index`, `show`, `new`, `edit`, `create`, `update`, `destroy`). Avoid custom member/collection actions. Introduce a new resource controller instead.

---

## 🔮 4. Decorator / Presenter Pattern

Views must remain lightweight and declarative.

- **Model Decoration**: Any model requiring custom visual formatting (dates, localized state badges, icon strings) must be wrapped in a decorator located in `app/decorators/` extending `ApplicationDecorator`.
- **View Separation**: Never perform date calculations, localized string mappings, or conditional color matches in ERB files. Call decorated methods instead.

---

## 🧹 5. Zero Comments Policy in Views & Controllers

- **No Comments in ERB**: Do not include ERB comments (`<%# ... %>`) or visual layout dividers inside view templates.
- **No Comments in Controllers**: Keep controllers clean, self-documenting, and free of step comments (`# ...`).

---

## ⚡ 6. Database Optimization

- **Batch Queries**: Consolidate multiple sequential `COUNT`, `SUM`, or `AVG` database checks on the same table into a single `select` query with inline conditional SQL statements to prevent query flooding.
- **Pluck Caching**: Avoid plucking IDs multiple times; reuse plucked arrays.

---

## 🛠️ 7. Dev Workflow & Tailwind CLI Watcher

- **Watcher Setting**: When starting Tailwind watching, always use the `--watch=always` flag in the CLI script.
- **Why**: This prevents Foreman (`bin/dev`) from silently shutting down the background compilation process when stdin is closed.

---

## 🌐 8. Internationalization (i18n) Standards

- **View Text**: All user-facing strings in ERB views must use `t()` calls. No hardcoded Spanish or English text.
- **Decorator Methods**: Date formatting and locale-dependent strings must live in decorators using `I18n.l()` and `I18n.t()`. `LetterDecorator#display_title` dynamically resolves default/placeholder letter titles according to the active locale.
- **JS in Views**: Inline JavaScript that sets text content must use Rails i18n helpers (e.g., `I18n.locale.to_s` instead of hardcoded `"es-ES"`).
- **Comments in HTML**: HTML comments visible in source should be in English, not Spanish.
- **Locale Files**: Keys must be consistent across `en.yml` and `es.yml`. The `en.yml` file must never contain Spanish text, and `es.yml` must contain Spanish translations for every key.
- **Locale Resolution**: The `set_locale` before_action in `application_controller.rb` checks `session[:locale]` first (set via `LocalesController`), falling back to `HTTP_ACCEPT_LANGUAGE` browser detection, and defaulting to `I18n.default_locale` (`:en`). `I18n.fallbacks = true` is configured for production and testing.
- **Test Locale**: Tests establish `I18n.locale = :es` globally in `test_helper.rb` to ensure all assertions match Spanish expectations. The `set_locale` method respects this since no `Accept-Language` header or preset session locale is sent in tests by default.

---

## 🔀 9. Pull Request Formatting Rule

- **Template Standard**: When the user requests a "pull request", AI agents must structure the pull request description strictly adhering to the sections in `.github/pull_request_template.md`.
- **Direct Output Only**: AI agents must return the formatted pull request markdown directly in the chat response inside a single markdown code block for easy copying, without creating temporary markdown files (such as `.pr_body.md`).

---

## 💎 10. Automated Code Formatting & Linting (RuboCop)

- **Mandatory RuboCop Auto-correction**: Whenever any changes or additions are made to Ruby files (`app/`, `config/`, `lib/`, `test/`, etc.), AI agents must automatically run `bundle exec rubocop -a` (safe autocorrect) on the affected files or project.
- **Zero Offenses Policy**: Ensure zero RuboCop offenses remain uncorrected before completing any task.

---

## 🧰 11. Agent Skills Standard (`.agents/skills/`)

TimeEcho maintains specialized agent skills in the `.agents/skills/` directory to guide domain-specific workflows and enforce best practices across architecture, design, and copywriting. AI assistants must proactively reference these skill guides before undertaking relevant work:

- **`.agents/skills/rails-expert/` (`SKILL.md`)**: Modern Rails conventions, Hotwire (Turbo Frames & Streams), Active Record query optimization (eager loading, batch queries), background jobs with GoodJob, and robust test suite creation. Consult for complex Rails architecture or query design.
- **`.agents/skills/frontend-design/` (`SKILL.md`)**: Guidance for distinctive, intentional visual design, typography hierarchy, and avoiding generic UI/SaaS patterns. Essential when shaping new visual components.
- **`.agents/skills/impeccable/` (`SKILL.md`)**: Frontend design critique, UX audit, micro-interactions, responsive behavior, accessibility (WCAG AA), and visual polish.
- **`.agents/skills/copywriting/` (`SKILL.md`)**: Conversion-oriented copywriting, hero messaging, value propositions, and editorial text guidance.
- **`.agents/skills/find-skills/` (`SKILL.md`)**: Discovery and installation of new agent skills when extended workflows are requested.

### Operational Rules for Skills:
- **Directory Location**: All skills reside in `.agents/skills/<skill_name>/SKILL.md`.
- **Proactive Consultation**: Whenever a task touches an area covered by an existing skill (such as Rails optimizations, frontend styling, or copywriting), the agent should view and follow the corresponding `SKILL.md` instructions.
- **Skill Tracking**: Installed skills and their source origins are tracked in `skills-lock.json`.

---

## 📡 12. REST API Standards & Error Contract (v1)

TimeEcho exposes a standardized RESTful API under `app/controllers/api/v1/` following strict architectural boundaries:

### A. Pipeline & Separation of Responsibilities
- **Controllers (`Api::V1::BaseController`)**: Must include `Api::ApiResponse`, `Api::ResultHandler`, and `Api::ErrorHandler`.
- **Single-Line Action Flow**: Controller actions must delegate execution directly to service objects and wrap them with `unwrap!`:
  ```ruby
  def show
    @letter = unwrap!(Letters::AccessService.call(params[:id], current_user_email, include_archived: true))
  end
  ```
- **Prohibited Controller Patterns**:
  - ❌ **No `case result.error` or manual `unless result.success?`**: Error mapping must remain encapsulated inside `ResultHandler`.
  - ❌ **No manual `render json:`**: Success responses must render Jbuilder templates or use `render_no_content`. The only exception is `ExceptionsController#show`.
  - ❌ **No manual 4xx/5xx status assignments**: Handled exclusively by `ErrorHandler`.
  - ❌ **No `rescue` blocks inside actions**: Handled exclusively by `ErrorHandler`.

### B. ResultHandler Standard (`app/controllers/concerns/api/result_handler.rb`)
- **`unwrap!(result)`**: Returns the entity on `result.success?`. When `result.failure?`, raises the exception mapped in `RESULT_ERRORS` or falls back to `Api::BusinessRuleError` (`code: result.error.to_s`).
- **Never Renders**: `ResultHandler` must **never** call `render`.

### C. Authentication (401) vs Resource Not Found (404) Rule
- **401 Unauthorized**: Returned for missing, invalid, or expired authentication tokens (`authenticate_user!`) and unauthenticated operations (`RESULT_ERRORS[:unauthorized]` ➔ `Api::UnauthorizedError`).
- **404 Not Found**: Returned when an authenticated user attempts to access, modify, or delete a resource they do not own or that does not exist (`Api::NotFoundError`). Never return 403 or 401 for unowned resources to prevent resource existence leakage.

### D. Response Contract & Key Formatting
- **Keys in `camelCase`**: Guaranteed globally via `config/initializers/jbuilder.rb` (`camelize: :lower` and `deep_format_keys true`).
- **Resource Envelope**: `{ "data": { ... }, "meta": {} }`.
- **Collection Envelope**: `{ "data": [ ... ], "meta": { "page": 1, "perPage": 20, "total": 134, "totalPages": 7 } }` via `paginate(scope)` from `Api::ApiResponse`.
- **Error Envelope**: `{ "error": { "code": "...", "message": "...", "details": { ... }?, "requestId": "..." } }`.
- **Unhandled Exceptions**: Caught by `config.exceptions_app` (`Api::V1::ExceptionsController#show`) and `Rack::Attack` throttler to preserve the JSON contract.

---

## ✅ Progress Summary

The following tasks have been completed:

- Created comprehensive UI/UX Design System and Architectural Specification in **[`docs/ui-ux.md`](docs/ui-ux.md)**.
- Implemented Postal & Archival Design System across all core views (`letters/index`, `letters/new`, `letters/show`, `pages/landing`, `sessions/new`).
- Established tripartite typography system: Fraunces (`font-serif-editorial`), Courier Prime (`font-letter`), and IBM Plex Sans (`font-ui`).
- Unified color palette to authentic postal tones (Wax Seal Carmine `#8E2818`, Postmark Indigo `#2C485E`, Manila `#EFECE3`, Parchment `#FAF9F5`), eliminating all purple/violet hues.
- Designed and generated high-contrast circular wax seal favicon and app icons with true 32-bit RGBA alpha transparency (`(0,0,0,0)`).
- Cleaned up marketing copy by removing testimonial quote sections and obsolete locale keys.
- Added missing `letters.*` locale keys to both `en.yml` and `es.yml` (total ~60+ keys)
- Replaced all hardcoded Spanish text in `letters/index.html.erb` with `t()` calls
- Replaced all hardcoded Spanish text in `letters/new.html.erb` with `t()` calls (including JS locale references)
- Replaced all hardcoded Spanish text in `letters/show.html.erb` with `t()` calls
- Replaced all hardcoded Spanish and English fallbacks in `layouts/application.html.erb`
- Converted HTML comments in `layouts/application.html.erb` from Spanish to English
- Implemented interactive language switch button in the navigation header with session persistence via `LocalesController` (`POST /locales`, `DELETE /locales/:id`).
- Implemented timezone-aware letter scheduling (`scheduled_at` in UTC + `timezone` IANA column) with automatic browser timezone detection.
- Separated `TimeCapsuleMailer` into `AuthMailer` and `LetterMailer`.
- Added `Letters::DeliverLetterJob` worker with polynomial backoff retries (`retry_on`) for transient connection errors and status transition tracking (`pending` ➔ `queued` ➔ `delivered`/`failed`).
- Configured production deployment pipeline (single-mode Puma with `WEB_CONCURRENCY=0`, GoodJob async mode).
- Consolidated schema attributes into `db/migrate/20260520000001_create_letters.rb`.
- Migrated all agent skills to `.agents/skills/` folder, updated `skills-lock.json` and documented skills standard in `AGENTS.md`.
- Completed Impeccable technical audit & quality certification (`19.7/20` score, zero anti-patterns detected).
- Hardened form accessibility (WCAG AA) with explicit label associations, ARIA attributes on range sliders and progress bars, and elevated placeholder contrast.
- Adapted layouts for mobile devices (`viewport-fit=cover`, safe-area insets, $\ge 44 \times 44\text{ px}$ touch targets, responsive text-wrap).
- Optimized font loading performance by removing render-blocking CSS `@import` and utilizing parallel preconnect links with `display=swap`.
- Optimized landing page and marketing copy across bilingual locale files (`en.yml`, `es.yml`), eliminating inaccurate feature claims (photo/audio uploads) and introducing action-oriented benefit CTAs.
- Comprehensive documentation update across `docs/architecture.md`, `docs/ui-ux.md`, `README.md`, `GEMINI.md`, and `AGENTS.md`.
- **Standardized API v1 Responses & Error Handling**:
  - Implemented `Api::ApiResponse`, `Api::ResultHandler`, and `Api::ErrorHandler` concerns with full single-responsibility boundaries.
  - Established unified JSON response contracts (`{ data, meta }` and `{ error }`) with camelCase keys across all levels.
  - Implemented Pagy pagination (`paginate(scope)`) with bounds clamping (1..100) and eager loading protection against N+1 queries.
  - Created domain exception hierarchy (`ApiError`, `NotFoundError`, `UnauthorizedError`, `ForbiddenError`, `BusinessRuleError`, `RateLimitedError`, `ServiceUnavailableError`).
  - Corrected permission denial mapping from 401 to 403 Forbidden.
  - Configured `config.exceptions_app` via `Api::V1::ExceptionsController` and updated `Rack::Attack` throttler to preserve the JSON error contract for out-of-controller exceptions.
  - Built comprehensive Minitest suite covering all status codes (400 through 503) and Result unwrapping.


