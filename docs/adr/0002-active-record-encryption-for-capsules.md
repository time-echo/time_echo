# ADR-002: Active Record Encryption for Letters and Predictions

## Status
Accepted

## Context
TimeEcho stores deeply personal, sensitive user thoughts, emotional states, and predictions about future milestones (career, salary, relationships, achievements). A database compromise or unauthorized operator access must not expose plaintext epistolary data.

## Decision
Employ Rails built-in **Active Record Encryption** with deterministic and non-deterministic field encryption:
- Encrypt `title` and `content` on `Letter`.
- Encrypt `prediction` and `reality` on `Prediction`.
- Keep scheduling metadata (`scheduled_at`, `status`, `timezone`, `language`) unencrypted to enable efficient database index lookups and job scheduling without in-memory decrypt passes.

## Alternatives Considered
- **Application-level PGP / asymmetric client-side encryption**: High complexity for non-technical users; prevents server-side email dispatch on scheduled arrival dates.
- **Full database disk encryption (TDE)**: Protects physical disk theft but does not isolate sensitive fields from application memory or read-replica dumps.
- **Custom AES-GCM cipher wrappers**: Adds custom cryptographic maintenance overhead compared to Rails battle-tested Active Record Encryption.

## Consequences
- **Positive**: Transparent cryptographic security at rest, key rotation support, compliance with data protection standards.
- **Negative**: Encrypted columns cannot be searched with standard SQL `LIKE` queries; search is restricted to unencrypted metadata (stamps, dates, categories).

## Trade-offs
Confidentiality of user reflections is prioritized over arbitrary full-text server searching.
