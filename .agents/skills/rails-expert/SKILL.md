---
name: rails-expert
description: Rails 7+ & 8 specialist that optimizes Active Record queries with includes/eager_load, implements Turbo Frames and Turbo Streams for partial page updates, configures Action Cable for WebSocket connections, sets up Sidekiq and Active Job workers with modern retry/discard mechanisms, and writes comprehensive RSpec test suites. Use when building Rails 7+ and 8 web applications with Hotwire, real-time features, or background job processing. Invoke for Active Record optimization, Turbo Frames/Streams, Action Cable, Sidekiq, RSpec Rails.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "1.2.0"
  domain: backend
  triggers: Rails, Ruby on Rails, Hotwire, Turbo Frames, Turbo Streams, Action Cable, Active Record, Sidekiq, RSpec Rails
  role: specialist
  scope: implementation
  output-format: code
  related-skills: fullstack-guardian, database-optimizer
---

# Rails Expert

## Core Workflow

1. **Analyze requirements** — Identify models, routes, real-time needs, background jobs
2. **Scaffold resources** — `rails generate model User name:string email:string`, `rails generate controller Users`
3. **Run migrations** — `rails db:migrate` and verify schema with `rails db:schema:dump` (verify project-specific migration execution constraints if automated)
   - If migration fails: inspect `db/schema.rb` for conflicts, rollback with `rails db:rollback`, fix and retry
4. **Implement** — Write controllers, models, add Hotwire (see Reference Guide below)
5. **Validate** — `bundle exec rspec` (or `bin/rails test`) must pass; `bundle exec rubocop` for style
   - If specs fail: check error output, fix failing examples, re-run with `--format documentation` for detail
   - If N+1 queries surface during review: add `includes`/`eager_load` (see Common Patterns) and re-run specs
6. **Optimize** — Audit for N+1 queries, add missing indexes, add caching

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Architectural Patterns | `references/architectural-patterns.md` | Service objects, form objects, query objects, directory contract, concern hygiene |
| Hotwire/Turbo | `references/hotwire-turbo.md` | Turbo Frames, Streams, morphing, Stimulus controllers |
| Active Record | `references/active-record.md` | Models, associations, `normalizes`, queries, performance |
| Background Jobs | `references/background-jobs.md` | Active Job (`retry_on`/`discard_on`), Sidekiq 7 (`Sidekiq::Job`), queues |
| Testing | `references/rspec-testing.md` | Transactional fixtures, system specs (`headless_chrome`), model/request specs |
| API Development | `references/api-development.md` | API-only mode, modern serialization (Alba), authentication |

## Common Patterns

### N+1 Prevention with includes/eager_load

```ruby
# BAD — triggers N+1
posts = Post.all
posts.each { |post| puts post.author.name }

# GOOD — eager load association
posts = Post.includes(:author).all
posts.each { |post| puts post.author.name }

# GOOD — eager_load forces a JOIN (useful when filtering on association)
posts = Post.eager_load(:author).where(authors: { verified: true })
```

### Turbo Frame Setup (partial page update)

```erb
<%# app/views/posts/index.html.erb %>
<%= turbo_frame_tag "posts" do %>
  <%= render @posts %>
  <%= link_to "Load More", posts_path(page: @next_page) %>
<% end %>

<%# app/views/posts/_post.html.erb - pass record directly instead of interpolating strings %>
<%= turbo_frame_tag post do %>
  <h2><%= post.title %></h2>
  <%= link_to "Edit", edit_post_path(post) %>
<% end %>
```

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = Post.includes(:author).page(params[:page])
  @next_page = @posts.next_page
end
```

### Modern Background Job (Active Job with native retry/discard)

```ruby
# app/jobs/send_welcome_email_job.rb
class SendWelcomeEmailJob < ApplicationJob
  queue_as :default

  # Native Active Job retry/discard handling
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end

# Enqueue with JSON-safe primitives (avoid symbols for strict Sidekiq 7 argument checking)
SendWelcomeEmailJob.perform_later(user.id)
```

### Pure Sidekiq 7+ Worker (Sidekiq::Job)

```ruby
# app/sidekiq/send_welcome_email_job.rb
# Note: include Sidekiq::Job replaces deprecated Sidekiq::Worker in Sidekiq 7+
class SendWelcomeEmailJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  rescue ActiveRecord::RecordNotFound
    # Discard missing record
  end
end
```

### Strong Parameters (controller template)

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post, notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published_at)
  end
end
```

## Constraints

### MUST DO
- Prevent N+1 queries with `includes`/`eager_load` on every collection query involving associations
- Use Rails 7.1+ `normalizes` for attribute formatting (emails, phone numbers, usernames) instead of manual callbacks
- Write comprehensive specs targeting >95% coverage with transactional fixtures
- Use service objects for complex business logic; keep controllers thin
- Add database indexes for every column used in `WHERE`, `ORDER BY`, or `JOIN`
- Offload slow operations to background jobs — never run them synchronously in a request cycle

### MUST NOT DO
- Use deprecated `Sidekiq::Worker` (use `Sidekiq::Job` in Sidekiq 7+)
- Use `sidekiq_options` inside `ApplicationJob` (use native `retry_on` / `discard_on`)
- Use deprecated `DatabaseCleaner` when Rails transactional fixtures (`config.use_transactional_fixtures = true`) suffice
- Use unmaintained `active_model_serializers` (use modern serializers like Alba or Blueprinter)
- Skip migrations for schema changes
- Use raw SQL without sanitization (`sanitize_sql` or parameterized queries only)
- Expose internal IDs in URLs without consideration

## Output Templates

When implementing Rails features, provide:
1. Migration file (if schema changes needed)
2. Model file with associations and validations
3. Controller with RESTful actions and strong parameters
4. View files or Hotwire setup
5. Spec files for models and requests
6. Brief explanation of architectural decisions

[Documentation](https://jeffallan.github.io/claude-skills/skills/backend/rails-expert/)
