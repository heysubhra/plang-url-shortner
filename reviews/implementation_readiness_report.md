# Stage 9: Implementation Readiness Test (Re-audit)

* **Target:** `docs/designs/local-url-shortener.md`
* **Detailed range:** Lines 178–214
* **Review date:** 2026-08-05
* **Project inspection:** `~/projects/url-shortener/` contains only the copied design and concepts brief; there is no application source to reuse.

## Findings

### Major — Setup and execution steps are not reproducible yet

**Affected scope:** Suggested folder structure; Implementation outline.

The project root, framework, database, `.env` values, and user-visible behavior are specified, and the folder structure is explicitly suggestive. However, the plan leaves dependency versions and how to install, run, and test the app to implementation. The new project has no existing setup to reuse.

**Recommendation:** Add only the minimum setup needed for a reproducible start, such as a supported Python version, dependency-manifest approach, and run/test commands. Keep module boundaries and the folder tree optional.

### Major — Verification does not specify expected assertions

**Affected scope:** Implementation outline; Verification Plan.

The plan names user journeys but does not list required assertions for invalid destinations, cross-owner removal, CSRF rejection, invalid configuration, non-reuse of a deleted code, persistence, or session behavior. “Automated checks” and “manually verify” leave too much interpretation for a build handoff.

**Recommendation:** Add a concise checklist of required cases and expected results. Test file locations and organization can remain implementation choices.

### Major — Outline has no stable incremental checkpoints

**Affected scope:** Implementation outline.

The outline gives broad activities but does not state what should be runnable and verified after each phase. This makes it harder to keep the new project buildable during development.

**Recommendation:** Name a few observable outcomes, such as app starts with valid configuration, account flows work, and link ownership/redirect behavior passes. Do not require a fixed file-by-file sequence.

### Nit — Session secret generation is not explained

**Affected scope:** Suggested folder structure and `.env.example`.

The example includes `SESSION_SECRET` but does not label its value as a placeholder or explain how to create a private local value.

**Recommendation:** Add a short generation instruction in setup guidance; never put a real secret in the example file.

### Nit — Concepts brief link does not resolve in the workspace copy

**Affected scope:** Additional Resources in the design document.

The relative link `./concepts_brief.md` works in the copy under `~/projects/url-shortener/docs/designs/`, where both documents are siblings. In the workspace, the design is under `docs/designs/` while the brief is at the workspace root, so the link is broken there.

**Recommendation:** Keep a sibling copy of the brief in the workspace design directory or change the link strategy so it works in both locations.

## Prior findings now addressed

The target now defines HTTP 404 for unknown/removed codes; requires that removed codes are never reused while leaving the SQLite mechanism open; specifies root `.env` loading and clear startup failure for invalid required settings; describes basic URL validation; normalizes email addresses; and treats the supplied password regex as the complete rule. The user also confirmed that localhost-only access is an intentional requirement and that broader URL hardening, automated recovery, and throttling are future enhancements.

## Readiness assessment

The concise, suggestive structure matches the user's preference and is not itself a defect. The design is not a complete build handoff under the implementation-readiness standard because setup commands, phase outcomes, and expected test assertions remain open. These can be added briefly without prescribing module boundaries or every file.

## Resolution status

The approved refinements are now present in the design: a Python 3.11+ setup, `requirements.txt` dependency approach, root `.env` setup and run/test commands, private `SESSION_SECRET` generation, example-only port/base URL values, three observable implementation outcomes, and expected assertions for the specified behaviors. A sibling concepts-brief copy now resolves the relative resource link in the workspace as well as the new project. The Stage 9 re-audit cap has been reached, so these changes were not re-audited.
