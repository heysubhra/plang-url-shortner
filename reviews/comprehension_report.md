# Stage 6: Comprehension Test (Follow-up)

* **Target:** `docs/designs/local-url-shortener.md`
* **Feature range:** Lines 1–179
* **Detailed range:** Lines 180–216
* **Review date:** 2026-08-05

## Findings

### Major — Unknown and removed URL response is not fully defined

**Affected scope:** `concepts_brief.md` → Risks and limits; design → Goals, CUJs, and Request flows.

The brief leaves the HTTP status and page content open, while the design says only “application error.” A new implementer cannot tell what visitor-facing result is required.

**Clarification:** Specify the required status and a simple response, or explicitly mark the exact status/page as an implementation choice.

### Major — Code retirement behavior is not explained

**Affected scope:** Design → CUJ 1; Data and persistence; ByteByteGo notes.

The design says deleted codes are not reused but does not say how SQLite preserves uniqueness after a link row is removed. A reader cannot tell whether link deletion is logical or physical, or how the Base62 ID remains retired.

**Clarification:** State the required observable behavior and allow the implementation to choose a minimal persistence mechanism, or explicitly require a mechanism such as non-reused SQLite IDs.

### Major — `.env` loading and invalid configuration behavior are unspecified

**Affected scope:** Design → Open Questions, Network boundary, and Suggested folder structure.

The document lists settings and says to keep `.env` private, but does not say how the app loads the file or what happens when required values are missing or invalid. Dependency and setup details are deferred, limiting reproducibility.

**Clarification:** Require a documented local startup method, loading `.env` from the project root, and a clear startup error for invalid required settings. Keep package versions and exact file layout as implementation choices if desired.

### Nit — Email identity rules are incomplete

**Affected scope:** Design → Request flows.

The email column is unique and duplicate signup is rejected, but trimming, case sensitivity, and email syntax validation are not specified.

**Clarification:** State whether email is compared as entered or normalized (including case), and reject malformed addresses.

### Nit — Password character set is ambiguous

**Affected scope:** Design → Password rule.

The supplied regular expression specifies length and character classes, but `.` permits whitespace and Unicode characters by default. It is unclear whether those characters are allowed.

**Clarification:** State whether the regex is the complete rule as supplied or whether passwords are restricted to ASCII/non-whitespace characters.

## Overall assessment

The revised scope is understandable and consistent across the design and brief: the app is localhost-only, all configuration is in `.env`, links are publicly followable on that machine but owner-managed, and sessions have no application-defined expiry. The remaining findings concern implementation behavior that should either be defined or explicitly left as implementation choices.
