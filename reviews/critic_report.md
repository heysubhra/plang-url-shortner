# Stage 7: Critic Review

* **Target:** `docs/designs/local-url-shortener.md`
* **Feature range:** Lines 1–179
* **Review date:** 2026-08-05

## Author disposition after review comments

- **Localhost boundary:** Accepted as a requirement. The design now says localhost excludes remote machines but does not isolate users or processes on the host; the trusted-machine limitation is explicit.
- **URL validation:** The design now states a basic validation contract. Broader URL safety improvements can remain future enhancements.
- **Base62 IDs:** Checked the ByteByteGo course. It uses a unique ID generator and notes sequential IDs are guessable; it assumes links cannot be deleted or updated. The design adopts Base62 IDs and separately requires that a deleted code never be reused.
- **Backups:** Manual copy/restore while stopped and an integrity check are documented. Automated backup/recovery remains a future enhancement; no recovery or data-loss guarantee is made.
- **Authentication risks:** Duplicate-email disclosure and unthrottled login attempts are accepted first-version risks for a trusted local machine. Generic signup responses and throttling remain future enhancements.

## Findings

### Major — Localhost is a network boundary, not a per-user security boundary

**Affected scope:** Overview; Data and persistence; Network boundary; Non-Functional Requirements.

Binding to `127.0.0.1` blocks remote machines, but any process or user on the same machine may still reach the app. The app supports multiple accounts, uses sessions with no application-defined expiry, and serves links publicly to local users. The design should not imply that localhost protects one account from another local user or process.

**Recommendation:** State this threat boundary plainly. Keep owner checks for link management, explain session behavior and its local-machine risk, and decide whether this level of protection is acceptable for the intended use.

### Major — URL validation is not fully specified

**Affected scope:** Request flows; Non-Functional Requirements.

The design restricts destinations to HTTP/HTTPS but does not define what counts as a valid absolute URL. Malformed authorities, absent hosts, credentials, whitespace, or control characters could be accepted inconsistently and produce unsafe redirects.

**Recommendation:** Define the minimum validation contract: absolute URL, valid host, HTTP/HTTPS scheme, and rejection behavior for malformed or credential-bearing input. Keep the implementation mechanism open.

### Major — Base62 IDs need an explicit no-reuse invariant

**Affected scope:** Data and persistence; CUJ 1; Relevant points from the ByteByteGo design.

The design says codes come from SQLite-generated IDs and must not be reused after deletion, but does not state how that invariant is guaranteed. A generated row ID may be reused depending on table configuration.

**Recommendation:** Keep the behavior requirement that deleted codes never point to a new link. State that the ID source must not reuse deleted values, while leaving the specific SQLite mechanism to implementation.

### Major — Backup and recovery expectations remain thin

**Affected scope:** Network boundary and operational limits; Non-Functional Requirements.

The design places backups on the operator and says to copy the database while stopped, but gives no restore check or acceptable data-loss expectation. A disk failure can permanently lose all accounts and links.

**Recommendation:** Explicitly state that there is no automated recovery or availability guarantee in version one, and give a minimal manual backup/restore procedure with a database integrity check. Avoid adding a backup service unless the user requires it.

### Major — Accepted authentication risks need clearer boundaries

**Affected scope:** Request flows → signup; Non-Goals; Future Improvements.

A duplicate-email message reveals whether an account exists, and rate limiting is deferred. The design lists generic signup responses as a future improvement but does not clearly state this is an accepted first-version risk. Localhost still permits local users or processes to make repeated requests.

**Recommendation:** Label account enumeration and unthrottled attempts as accepted first-version risks, and make clear the app is for a trusted single-machine environment. Keep the deferred improvements visible rather than implying these risks are mitigated.

### Nit — Redirect error wording is inconsistent

**Affected scope:** Goals; CUJs; Request flows.

The document alternates between “application error,” “not-found page,” and HTTP 404 for unknown or removed codes.

**Recommendation:** Use one user-facing description and state the HTTP status. A 404 is consistent with an unknown or removed short code.

### Nit — Course notes mix source guidance with local decisions

**Affected scope:** Relevant points from the ByteByteGo design.

The section combines course guidance, the app's choices, and high-scale estimates. It includes “Bloom filter” and “sharding,” which add jargon without helping the localhost design.

**Recommendation:** Keep the useful mapping, Base62, and 301/302 trade-offs; label which choices this app adopts. Summarize the course's high-scale infrastructure as out of scope without listing unrelated technologies.

### Nit — Framework alternative does not compare trade-offs

**Affected scope:** Alternatives Considered → Use a different Python web framework.

The rationale mainly says FastHTML was selected, without explaining its fit or the security/session work it leaves to the application compared with Django or Flask.

**Recommendation:** Add a short, evidence-based reason for using FastHTML for a small server-rendered local app, and note that account security remains application responsibility.

## Structural and style notes

- The section ordering is readable; there is no mandatory ordering violation under the feature-spec standard.
- Put the password character requirements in readable prose beside the regex so users need not infer them from punctuation escaping.
- The specification should describe how duplicate signup, invalid login, failed removal, and unknown-code responses appear to the user.
