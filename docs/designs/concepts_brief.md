# Local URL Shortener

* **Author:** Not specified
* **Date:** 2026-08-05

## Overview

Build a web application available only on the same machine through localhost, using SQLite for persistent data. Multiple people can sign up with an email address and password, sign in, create short links, and remove links they own. Anyone using that machine can follow a short link without signing in. Destinations must use HTTP or HTTPS. All runtime settings are stored in `.env`.

Password recovery, email verification, and rate limiting are not part of the first version. Passwords must meet the agreed complexity rule and be stored as hashes. Sessions have no application-defined expiry.

## Analysis

### Problem and intended use

The app gives people using one machine a way to create and manage short links without relying on an external shortening service. It is localhost-only. There is no stated traffic or availability target, and no unlimited-capacity guarantee. The design should remain proportionate to a small, single-machine service.

### Main user flows

- A person signs up and signs in with an email address and password.
- A signed-in person creates a short link and can see their own links.
- A signed-in person removes a link they own. Other accounts cannot remove it.
- A visitor using the same machine follows a short URL without signing in. An unknown or removed short URL returns HTTP 404 with a not-found response; errors at the destination are left to the visitor's browser.
- Destinations must be valid HTTP or HTTPS URLs. Other schemes are rejected.

The application binds only to localhost. Public links can be followed without sign-in, but only the owning account can remove them.

### Alternatives considered

- **SQLite rather than DuckDB or both:** SQLite is the chosen store for account and link records in a single-machine app. DuckDB is a separate database, not a layer over SQLite, and its analytical strengths are not required by the described flows. Keeping both would add operational and implementation complexity without a stated need.
- **Build rather than use an existing shortening service:** An existing service would avoid maintaining account, storage, and redirect behavior. The proposed app is justified if local ownership on one machine is important; if it is not, using an existing service is simpler.
- **One machine rather than a hosted multi-service system:** A single-machine app fits the current scope. Distributed services, queues, and scaling machinery are not justified without a demonstrated need.

### Risks and limits

- **Network boundary:** The app binds to localhost and is available only on the machine running it. It does not provide LAN or public-internet access. Localhost does not isolate accounts from other users or processes on that same machine, so the app is intended for a trusted local environment.
- **Abuse and destination trust:** HTTP/HTTPS-only validation does not make a destination trustworthy. A short link can still lead to a misleading or harmful site. Require an absolute URL with a valid host and reject credentials and control characters. Rate limiting is deferred, so repeated login attempts are an accepted first-version risk on the trusted local machine; do not imply the app is suitable for public internet service.
- **Password and session safety:** Store password hashes, not plain-text passwords. Sessions have no application-defined expiry, so users should sign out when finished, especially on a shared browser. Duplicate-email disclosure and unthrottled login attempts are accepted first-version risks. Password recovery and email verification are out of scope. Link ownership is enforced for management actions; public short URLs remain followable without signing in.
- **SQLite durability and availability:** The machine and its storage are a single point of failure. Accounts and links must survive an application restart. Automated backup is out of scope; the operator makes manual backups. SQLite write contention and disk exhaustion may limit use; no workload or availability target has been provided.
- **Short-code behavior:** Encode generated database IDs as Base62, following one approach described in the ByteByteGo course. The ID source must not reuse values after deletion; the implementation can choose the SQLite mechanism. Codes are sequential and guessable; this is accepted because links are public and the app is localhost-only.
- **Error behavior:** Unknown or removed codes return HTTP 404 with a not-found response rather than a redirect or internal error. Destination failures occur after redirect and are outside the app's control.
- **No legacy migration:** This is a new application with no existing accounts or link records to migrate. A database schema-upgrade approach is still needed before releases that change the stored data format.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  * Run as a web application bound to localhost and use SQLite for persistent data.
  * Support multiple accounts with email-and-password signup and sign-in.
  * Let signed-in users create links and remove only links they own.
  * Let unauthenticated visitors on the same machine follow short URLs.
  * Accept absolute HTTP and HTTPS URLs with a valid host; reject credentials and control characters.
  * Preserve account and link data across application restarts.
  * Return HTTP 404 with a not-found response for unknown or removed short URLs.

* **Out-of-Scope Non-Goals:**
  * Public-internet exposure or a distributed/multi-machine service.
  * Password recovery and email verification.
  * Rate limiting in the first version; basic throttling is a future enhancement.
  * Link editing, click analytics, custom aliases, expiration, or other unspecified link features.
  * Handling failures at the destination website.
  * Unlimited capacity guarantees; no volume or performance target has been set.

## Key Decisions & Staging for Next Steps

### Decisions resolved during ideation

- The app runs on one machine, binds to localhost, uses SQLite (not DuckDB), and stores account and link data across restarts. All runtime settings are in `.env`.
- There can be multiple accounts. Trim and lowercase email addresses before storing and comparing them; reject malformed addresses, and keep the normalized email field unique. Passwords must be 12–30 characters and include uppercase, lowercase, a digit, and at least one character from the agreed punctuation set.
- Users can create and remove their own links; they cannot edit destinations.
- Short links can be followed without signing in by people on the same machine. The app is not accessible from other machines.
- Only HTTP and HTTPS destinations are accepted.
- Password recovery and email verification are out of scope. Sessions do not have an application-defined expiry. Rate limiting is deferred as a future enhancement.
- Unknown or removed short links return HTTP 404 with a not-found response; failures at the destination are left to the browser. Redirects use 302 so requests return to the app after a link is removed.

### Course concepts used in the design

The ByteByteGo course describes a persistent short-code-to-destination mapping and compares hash-based codes with Base62-encoded unique IDs. It notes that incrementing IDs make nearby codes easy to guess. This design adopts Base62 IDs and accepts that trade-off because links are public on the local machine. The course assumes short URLs cannot be deleted or updated; this app allows removal, so the requirement not to reuse deleted IDs is specific to this design. It uses 302 redirects rather than 301 because browsers may cache permanent redirects, which could prevent a later removal from taking effect.

The course's global-service estimates (100 million links per day, 11,600 reads per second, and tens of terabytes of storage) do not apply to this localhost-only app. Distributed infrastructure is out of scope.

### Remaining setup

The operator supplies `BIND_HOST=127.0.0.1`, `PORT=5001`, `APP_BASE_URL=http://localhost:5001`, `DATABASE_PATH=data/shortener.sqlite3`, and `SESSION_SECRET` in the local `.env` file and keeps that file private. The new application project is created at `~/projects/url-shortener/`.
