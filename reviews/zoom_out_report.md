# Stage 5: Initial Zoom Out Review (Re-audit)

* **Target:** `docs/designs/local-url-shortener.md` (lines 1–210)
* **Review date:** 2026-08-05
* **Context:** The user confirmed `~/projects/url-shortener/` is a new application root to create, separate from the notes workspace.

## Findings

### Major — The implementation plan still fixes too much before the first build

**Affected scope:** `Detailed Implementation Plan` → `Files to create` and `Verification Plan`.

The plan is shorter, but it still prescribes a multi-module layout, detailed test inventories, exact password bounds, migration machinery, and SQLite connection behavior before implementation validates the smallest workable FastHTML pattern. This risks turning a small single-process app into a prescribed mini-framework.

**Recommendation:** Keep the app root and essential deliverables, but let implementation determine the smallest workable module layout. Retain the security, ownership, persistence, URL-validation, and user-visible behavior requirements. Make the syntax-check command follow the files actually created, or rely on the test suite and essential end-to-end checks.

### Accepted trade-off — Duplicate-email disclosure

The design clearly states that duplicate addresses receive an “already registered” message in the first version, that this reveals whether an account exists, and that a generic response is deferred. No change is needed for this review.

### Context clarified — New project root

The design correctly separates the new application root, `~/projects/url-shortener/`, from the notes workspace and says it must be created during implementation. There is no existing app source tree to inspect for code reuse.

## Overall assessment

The single-process SQLite architecture fits the stated local-network use, and the document states its major security and operational limits. The remaining concern is the amount of prescribed implementation structure, not the feature scope.

## Author-requested update after review

The author asked to make the folder layout suggestive and remove low-level implementation prescriptions. `docs/designs/local-url-shortener.md` has since been revised to keep the objective and accepted constraints, show a suggested folder structure, and shorten the implementation plan. Stage 5 was not rerun after this edit; this report reflects the prior version.
