# Rails Architectural Patterns (Rails 7.1+ & 8.x)

Framework architectural patterns for modern Ruby on Rails applications. This reference covers directory structure, object-oriented service and query abstractions, and boundary hygiene.

---

## 1. The Directory Contract

Maintain a predictable and intention-revealing Rails architecture:

```
app/
  models/         ActiveRecord models. Persistence and domain logic close to the data.
  controllers/    HTTP request handling. Thin orchestration only.
  views/          ERB templates. Lightweight presentation.
  components/     ViewComponent classes. Complex view logic requiring isolated tests.
  services/       Service objects. Multi-step business operations.
  forms/          Form objects. Multi-model form handling and parameter validation.
  queries/        Query objects. Reusable, composable ActiveRecord queries.
  jobs/           Background jobs. Async processing via Solid Queue, Sidekiq, or GoodJob.
  mailers/        ActionMailer notification classes.
  helpers/        View helpers. Tiny formatting utilities only.
  policies/       Authorization policies (Pundit / ActionPolicy).
  channels/       ActionCable channels for WebSocket handling.
```

> **Anti-pattern**: Avoid ad-hoc directories like `app/lib/`, `app/utils/`, or `app/managers/`. Truly generic code belongs in top-level `lib/`.

---

## 2. Skinny Controllers

Controllers receive an HTTP request, authorize the user, delegate execution to a domain service or query object, and render the response:

```ruby
# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  def create
    result = Invoices::Create.call(params: invoice_params, user: current_user)

    if result.success?
      redirect_to result.invoice, notice: "Invoice created."
    else
      @invoice = result.invoice
      render :new, status: :unprocessable_entity
    end
  end
end
```

---

## 3. Service Objects

Use service objects for operations that mutate multiple models, dispatch notifications, or coordinate business workflows:

* **Namespace by Domain**: `Invoices::Create`, `Letters::ArchiveService` (never `InvoiceManager`).
* **Single Entry Point**: Class method `.call` delegating to `#call`.
* **Return a Result Object**: Return a structured `Result` with `success?`, entity payload, and errors (never a bare boolean).
* **Transaction Wrapping**: Wrap multi-record database writes inside an Active Record transaction.
* **Resilient Side Effects**: Isolate mailers or external API calls so failures do not abort successful database transactions.

```ruby
# app/services/invoices/create.rb
module Invoices
  class Create
    Result = Struct.new(:success, :invoice, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def self.call(params:, user:)
      new(params: params, user: user).call
    end

    def initialize(params:, user:)
      @params = params
      @user = user
    end

    def call
      invoice = user.invoices.new(params.except(:line_items))
      invoice.line_items.build(params[:line_items])

      ApplicationRecord.transaction do
        invoice.save!
      end

      dispatch_notifications(invoice)
      Result.new(success: true, invoice: invoice, errors: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, invoice: e.record, errors: e.record.errors)
    end

    private

    attr_reader :params, :user

    def dispatch_notifications(invoice)
      InvoiceMailer.created(invoice).deliver_later
      AccountingExportJob.perform_later(invoice.id)
    rescue StandardError => e
      Rails.logger.error("Notification dispatch failed for invoice #{invoice.id}: #{e.message}")
    end
  end
end
```

---

## 4. Form Objects

When a submission spans multiple models or contains virtual attributes requiring complex validation, use a Form Object rather than `accepts_nested_attributes_for`:

```ruby
# app/forms/signup_form.rb
class SignupForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string
  attribute :terms_accepted, :boolean

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, presence: true, length: { minimum: 12 }
  validates :company_name, presence: true
  validates :terms_accepted, acceptance: true

  attr_reader :user, :company

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      @company = Company.create!(name: company_name)
      @user = @company.users.create!(email: email, password: password, role: :owner)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end
end
```

---

## 5. Query Objects

Extract complex or multi-condition queries into composable Query Objects. A scope that exceeds three chained clauses or accepts multiple parameters should become a query object:

```ruby
# app/queries/invoices/overdue_query.rb
module Invoices
  class OverdueQuery
    def self.call(scope: Invoice.all, as_of: Time.current)
      new(scope: scope, as_of: as_of).call
    end

    def initialize(scope:, as_of:)
      @scope = scope
      @as_of = as_of
    end

    def call
      scope
        .where(status: :sent)
        .where(due_date: ..as_of)
        .where.not(id: paid_invoice_ids)
        .includes(:customer, :line_items)
    end

    private

    attr_reader :scope, :as_of

    def paid_invoice_ids
      Payment.where(created_at: ..as_of).pluck(:invoice_id)
    end
  end
end
```

Compose freely: `Invoices::OverdueQuery.call(scope: current_user.invoices)`.

---

## 6. Callback and Concern Hygiene

* **Pure Data Normalization Only in Callbacks**: Use `before_validation` or Rails 7.1+ `normalizes` strictly for formatting (e.g., stripping whitespace, downcasing emails).
* **No Side Effects in Callbacks**: Never enqueue jobs, send emails, or call external APIs inside `after_create` or `after_save`. Coordinate those explicitly in service objects.
* **Concern Rule of Two**: Only extract a concern (`ActiveSupport::Concern`) if the module is shared across at least **two unrelated models**. Single-model concerns merely obscure logic.

---

## 7. The Rails 8 Solid Stack

Rails 8 ships database-backed engines that eliminate external Redis requirements for modest throughput:
* **Solid Queue**: Database-backed Active Job adapter with native retries and concurrency limits.
* **Solid Cache**: Fast database-backed cache store replacing Redis/Memcached.
* **Solid Cable**: ActionCable WebSocket engine backed by PostgreSQL/MySQL.
* **Passing Primitives**: Always pass IDs and JSON-safe scalars to jobs, never full ActiveRecord instances.
