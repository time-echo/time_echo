# ADR-001: Passwordless Magic Link Authentication

## Status
Accepted

## Context
TimeEcho is an archival future-letter digital capsule platform where users compose personal letters to their future selves. Traditional username/password credentials present friction, credential reuse vulnerabilities, and account recovery overhead for an epistolary service visited periodically over years.

## Decision
Implement a passwordless authentication flow utilizing cryptographic single-use session tokens (`SessionToken`) dispatched via email magic links:
- Token generation using 48-character cryptographically secure random hexadecimal strings (`SecureRandom.hex(24)`).
- Strict 15-minute expiration window on magic links.
- Single-use invalidation (`used_at`) upon token exchange.
- Automatic revocation of prior active tokens upon login to eliminate orphaned active sessions.
- Dual-channel client authentication via `Authorization: Bearer <token>` or `X-Session-Token: <token>`.

## Alternatives Considered
- **Username / Password with bcrypt**: High friction for long-term capsule authors who may only check back months or years later.
- **Third-Party OAuth / Social Login (Google / GitHub)**: Increases external identity dependency and leaks metadata to third-party identity providers for sensitive personal writing.
- **JWT (JSON Web Tokens)**: Stateless JWTs cannot be easily revoked immediately without maintaining a distributed denylist, whereas database-backed `SessionToken` records allow instantaneous revocation and audit logging.

## Consequences
- **Positive**: Zero password storage attack surface, seamless user onboarding, instant token revocation.
- **Negative**: Reliance on email delivery latency (mitigated by asynchronous mail delivery through GoodJob and transactional mail providers).

## Trade-offs
Convenience and privacy are prioritized over instant offline authentication.
