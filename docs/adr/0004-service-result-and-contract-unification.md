# ADR-004: Unified ServiceResult and API Error Contract

## Status
Accepted

## Context
Across TimeEcho's domain services, heterogeneous ad-hoc Result structs had emerged with inconsistent method signatures (`value`, `letter`, `countdown`, `errors`, `code`). Additionally, RESTful API controllers required a uniform way to unwrap service outcomes into HTTP status codes or standard JSON error envelopes without polluting controllers with business logic.

## Decision
Introduce a canonical `ServiceResult` object (`app/services/service_result.rb`) alongside `Api::ResultHandler#unwrap!`:
- Provides first-class `success?` and `failure?` predicates.
- Exposes standardized payloads: `value`, `error`, `code`, `message`, `details`, and `errors`.
- Employs dynamic metadata accessors and backward-compatible aliases (`letter`, `form`, `countdown?`, `new_email`).
- Controller actions remain strictly one-line delegations: `@resource = unwrap!(Service.call(...))`.
- Errors are mapped declaratively by `ResultHandler::RESULT_ERRORS` to HTTP exceptions handled by `Api::ErrorHandler`.

## Alternatives Considered
- **Dry::Monads / dry-transaction**: Introduces external ruby gem dependencies and unfamiliar syntax idioms for standard Rails developers.
- **Raising exceptions inside services**: Violates the principle of reserving exceptions for truly exceptional errors, causing stack trace allocation overhead on standard domain validations.

## Consequences
- **Positive**: Consistent service contracts, 100% thin controllers, declarative error mappings, zero boilerplate.
- **Negative**: Developers must adhere to `ServiceResult.success(...)` and `ServiceResult.failure(...)` conventions when creating new services.

## Trade-offs
Predictable internal architecture and senior developer ergonomics are prioritized over arbitrary ad-hoc patterns.
