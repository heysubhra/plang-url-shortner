# Stage 7 Findings: Resolution Notes

* **Target:** `docs/designs/local-url-shortener.md`
* **Resolution date:** 2026-08-05

## Applied refinements

- Clarified that localhost blocks remote machines but does not isolate users or processes on the host. The app is for a trusted local machine; session expiry remains as chosen, with sign-out guidance and cookie protections documented.
- Defined destination validation at the requirement level: absolute HTTP/HTTPS URL, valid host, and rejection of credentials, malformed URLs, and control characters.
- Made non-reuse of deleted short-code IDs an explicit behavior requirement while leaving the SQLite mechanism to implementation.
- Standardized unknown and removed links on HTTP 404 with a not-found response.
- Described manual database backup and restore steps, including stopping the app and running SQLite's integrity check.
- Identified duplicate-email disclosure and unthrottled login attempts as accepted first-version risks for a trusted local environment.
- Clarified email normalization and uniqueness, invalid sign-in behavior, and the complete password-regex policy.
- Simplified the ByteByteGo discussion to the relevant database mapping, Base62, redirect, and scale trade-offs; removed unrelated infrastructure jargon.
- Explained FastHTML's fit for a small server-rendered app and that account security remains application responsibility.

## Deliberately retained choices

- No application-defined session expiry, password recovery, email verification, rate limiting, automated backups, or remote-machine access.
- No fixed SQLite ID-reuse mechanism; the no-reuse behavior is required, but implementation may choose how to guarantee it.
- The password policy remains the supplied regex, without additional ASCII-only or whitespace restrictions.

## Stage 9 resolution

All Stage 9 recommendations have been applied in the design: Python 3.11+, `requirements.txt`, root `.env` setup and setup/run/test commands, private `SESSION_SECRET` generation, and clearly labeled example port/base URL values (while retaining mandatory localhost binding). Added three observable implementation outcomes and concise required test assertions for signup/password/email, ownership, CSRF/session/cookies, destination validation, code non-reuse and 404/302, persistence, configuration failure, and localhost behavior. The suggested folder structure remains explicitly optional. A sibling concepts-brief copy makes its relative link resolve in the workspace and project copies. Original audit findings are retained above.
