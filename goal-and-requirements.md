---
id: local-url-shortener-goal
type: goal-and-requirements
title: Local URL Shortener Goal and Requirements
status: active
tags: [product, requirements]
---

# Local URL Shortener

*A private, single-machine app for creating and sharing short links.*

## Overview

The app lets people on one trusted machine manage short links without relying on an external shortening service. Account and link data persist locally. Signed-in users manage their own links; anyone accessing the app from that machine can follow a shared link without signing in.

## Problem Statement

People using one machine need a local way to create and manage short links. External services do not meet the requirement for local ownership and storage, while links still need to be easy to share with other users of that machine.

## Target Users

People who use the same trusted machine and need separate accounts for managing links. Visitors on that machine may follow shared links without an account.

## Key User Story

When a signed-in user submits a valid destination URL, they want a short URL they can share locally, so that visitors on the same machine can reach the destination without signing in. The owner can later remove the link, after which its short URL no longer redirects.

## Goals

- Let people create accounts and sign in with email and password.
- Let signed-in users create, list, and remove only their own short links.
- Let visitors follow active short links without signing in.
- Keep account and active-link data across application restarts.
- Restrict access to the same machine and accept only valid HTTP or HTTPS destinations.
- Verify critical behavioral requirements before implementation using a model-checked P model, then test the Python implementation against that model's expected behavior. Model checking the P model alone is not proof of correctness of the separate Python implementation.

## Non-Goals

- Public-internet hosting or access from other machines.
- Password recovery, email verification, or rate limiting.
- Editing destinations, custom aliases, expiration, click analytics, or destination-site health checks.
- Unlimited storage, traffic, availability, or automated backup and recovery.

## Success Conditions

- A signed-in user can create and see their own active links, but cannot manage another user's links.
- A valid active short URL returns a temporary redirect to its HTTP/HTTPS destination without requiring a session.
- Unknown and removed short codes return HTTP 404 and never redirect to another link; removed codes are never reused.
- Accounts and active links remain available after restart.
- The app listens only on localhost; its security assumptions do not treat localhost as isolation between users or processes on the machine.
- Critical state transitions and invariants are covered by a P model that passes PChecker, and the Python implementation has conformance tests for the model's expected outcomes.

## Capabilities

- Account signup, sign-in, and sign-out using normalized, unique email addresses and hashed passwords. Signup reports duplicate addresses; invalid sign-in uses a generic error. Passwords must satisfy the supplied 12–30-character rule requiring uppercase, lowercase, a digit, and an allowed punctuation character.
- Owner-scoped link creation, listing, and removal. Destinations must be absolute HTTP or HTTPS URLs with a valid host; credentials and control characters are rejected. Short codes use Base62-encoded unique IDs, and IDs are not reused after removal.
- Public resolution of active short codes to HTTP 302 redirects. Unknown and removed codes return a not-found response without exposing database details.
- Persistent local storage in SQLite and runtime configuration from a project-root `.env` file. Required missing or invalid configuration causes a clear startup failure.
- Signed sessions without an application-defined expiry; signing out clears the current session. Session cookies are `HttpOnly` and `SameSite=Lax`. State-changing forms require an unpredictable session-bound CSRF token.

## Non-Functional Requirements

- Bind to `127.0.0.1`; this limits network reachability but does not isolate users or processes on the host. The app is intended for a trusted single-machine environment, not an untrusted shared host.
- Never store plain-text passwords. Do not add restrictions beyond the specified password regex's own matching behavior.
- Do not promise a recovery-time or data-loss guarantee. Manual database backups are the operator's responsibility and require stopping the app.
- Preserve user data when the database schema changes.

## Technology

| Aspect | Choice | Rationale |
|---|---|---|
| Language and web framework | Python with FastHTML | A small server-rendered local web app. |
| Persistence | SQLite | Sufficient for a single-machine application and its account/link operations. |
| Verification model | P and PChecker, assisted by PeasyAI | Model-check critical state transitions before implementation; use Python conformance tests to check the separate implementation against expected model behavior. |

The detailed design and implementation notes remain in `docs/designs/local-url-shortener.md` as source material; this goal spec states the product scope and requirements rather than preserving the original document's implementation plan or alternatives research.
