# URL shortener statechart verification

This bounded TLA+ model is the executable check for [`docs/designs/statechart.md`](../../docs/designs/statechart.md). It checks the transitions whose failure would redirect a removed link, expose or mutate another account's links, accept a state-changing request without its session-bound CSRF token, or lose link history on restart.

## What is checked

- `Starting`, `Serving`, `StartupFailed`, restart, and request gating.
- Two fixed accounts (`alice`, `bob`) and two independent browser sessions.
- Three short-code slots (`1..3`), two valid HTTP/HTTPS destinations, and two invalid destination inputs.
- Owner-only list/remove, valid and invalid CSRF inputs, rejected mutations preserving the store, and public resolution while signed out.
- Active, retired, and never-allocated code behavior; a retired code cannot become active again.
- Redirect/404 response correctness and durable link state across restart.

Each TLA+ action is one atomic request, response, or runtime transition. The TLC `VIEW` collapses only the last-request, last-response, and audit-snapshot fields because they do not enable future actions; runtime, session, link, allocation, visibility, and restart state remain in the view. TLC explores all reachable behavioral states for these finite constants, including the interleavings of the two browser actors. This is exhaustive only for this abstract model and these bounds; it is not a proof of an eventual Python implementation, SQLite behavior, password handling, cookie cryptography, URL parsing, HTML, or process-crash recovery.

## Run

Read the current `/statechart` skill before running the check. From a scratch directory outside the repository, invoke its current statechart command on the repository's `LocalURLShortener.tla`, using the adjacent `LocalURLShortener.cfg` and `LocalURLShortenerView.ts`; write output to a new directory outside the repository, such as `/tmp/url-shortener-statechart-check`. The generated report should show no invariant violations and the chart should use the reader-facing labels from the view.

Do not copy the statechart launcher path or command flags into another skill: those belong to the installed `/statechart` skill and can change between machines.

## Reading failures

Treat an invariant violation as a real finding until the action and the corresponding rule in `docs/designs/statechart.md` have been compared. The shortest path is expressed in runtime, browser, code, and response terms by the view. A modeling error is only established by showing that the model action does not correspond to the documented transition; do not weaken an invariant to make the check pass.

## Coverage record

Covered source: `docs/designs/statechart.md`, especially the transition rules and invariants 1–10. The model's implementation references are the runtime/session/link state definitions and the `Start`, `Sign in`, `Sign out`, `Create link`, `List links`, `Remove link`, `Resolve code`, and restart transitions in that file.

Last verification: the model was checked while creating this skill. The sync commit is recorded in `verification/skills/verify-url-shortener-statechart/SKILL.md`; move it only after confirming that this model still describes the covered statechart at the new commit.
