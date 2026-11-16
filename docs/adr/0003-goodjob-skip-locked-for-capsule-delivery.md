# ADR-003: GoodJob and SKIP LOCKED for High-Concurrency Capsule Dispatch

## Status
Accepted

## Context
TimeEcho delivers digital capsules at specific target UTC timestamps. When multiple scheduler processes or background workers run simultaneously, race conditions could cause duplicate email dispatches or lock contention on the `letters` table.

## Decision
Utilize **GoodJob** backed by PostgreSQL alongside explicit row-level locking (`FOR UPDATE SKIP LOCKED`) in `PendingLettersQuery`:
- Periodic dispatch worker invokes `Letters::DispatchPendingService`.
- Queries pending letters where `scheduled_at <= Time.current` using `Letter.where(...).lock("FOR UPDATE SKIP LOCKED")`.
- Atomically transitions retrieved capsule IDs to `queued` within a transaction before queuing jobs.
- Enqueues discrete `Letters::DeliverLetterJob` instances using `ActiveJob.perform_all_later`.

## Alternatives Considered
- **Redis + Sidekiq**: Requires managing and monitoring a separate Redis infrastructure cluster, increasing operational cost and introducing network partitioning failure modes.
- **Optimistic Locking (`lock_version`)**: High rate of stale object conflicts under heavy parallel dispatch windows.
- **Pessimistic Locking without `SKIP LOCKED`**: Causes lock queue stalls across workers attempting to query the same table slice.

## Consequences
- **Positive**: Zero Redis dependency; Postgres ACID guarantees; zero duplicate deliveries under horizontal scaling; non-blocking worker parallelization.
- **Negative**: Relies on PostgreSQL features (`SKIP LOCKED`), binding backend to Postgres (already the primary datastore).

## Trade-offs
Simplicity and transactional reliability of a single PostgreSQL datastore are prioritized over cross-database portability.
