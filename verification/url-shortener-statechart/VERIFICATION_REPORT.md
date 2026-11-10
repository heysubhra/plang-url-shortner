# Local URL shortener statechart verification report

## Executive summary

The lifecycle described in [`docs/designs/statechart.md`](../../docs/designs/statechart.md) was checked with a bounded TLA+ model and TLC through the `/statechart` skill.

The final model passed every checked rule, including request gating, session-bound CSRF, owner-only link management, short-code non-reuse, redirect/404 behavior, restart persistence, type consistency, and no deadlock.

The verification was also tested against a deliberately broken model. Removing the owner check from link removal allowed `alice` to remove a link owned by `bob`. TLC found that violation in a six-state counterexample. The owner check was restored, and the clean model passed again.

This is evidence about the documented state-transition model. It is not evidence that the future Python/FastHTML application already implements those transitions: the application does not exist in this repository yet.

## Question being verified

Can every allowed ordering of startup, browser sessions, link creation/listing/removal, public resolution, and restart preserve the statechart's safety promises?

The main user harms are:

- a signed-in user changing another user's link;
- a removed short code becoming active again or pointing at a later destination;
- an unknown or retired code returning a redirect instead of HTTP 404;
- a state-changing request succeeding without a valid session-bound CSRF token;
- durable link state changing or disappearing across restart.

## Model and approach

The model is [`LocalURLShortener.tla`](./LocalURLShortener.tla), configured by [`LocalURLShortener.cfg`](./LocalURLShortener.cfg), with reader-facing labels in [`LocalURLShortenerView.ts`](./LocalURLShortenerView.ts).

Each model action is one atomic transition: a startup result, restart, sign-in/sign-out, list request, create/remove request, or public resolve request. TLC explores all reachable behavioral states for the finite model rather than sampling a few hand-written paths.

The model contains:

- two accounts: `alice` and `bob`;
- two independent browsers: `browser-a` and `browser-b`;
- three short-code slots (`1..3`), enough for create → remove → create;
- two valid HTTP/HTTPS destinations and two invalid destination inputs;
- valid and invalid browser-specific CSRF tokens;
- active links, retired IDs, allocation history, visible lists, and restart snapshots.

TLC uses the model's `View` to collapse only audit fields describing the immediately previous request and response. Runtime, session, link, allocation, visibility, and restart state remain in the view because they can affect future behavior. The report therefore describes behavioral state coverage, not every possible audit-record value.

## Rules checked

| Rule | Plain-language meaning |
| --- | --- |
| `TypeOK` | State values always have the shapes and domains expected by the model. |
| `OnlyServingAcceptsRequests` | User and redirect requests are accepted only while the app is serving. |
| `MutationBoundary` | An accepted create/remove has a signed-in session, valid CSRF, and the requesting account is the link owner. |
| `RejectedMutationPreservesStore` | A rejected create/remove does not change durable link state. |
| `ActiveLinkIntegrity` | Every active link has one real owner and one valid HTTP/HTTPS destination. |
| `VisibleListsOwnerOnly` | A browser sees only active links owned by its signed-in account. |
| `CodeHistory` | Active and retired codes are disjoint, allocation history is monotonic, and allocated codes have destinations. |
| `FreshCodeOnCreate` | A successful create uses a never-allocated code. |
| `ResponseCorrect` | Active resolution returns 302, missing/retired resolution returns 404, and create/remove responses match storage. |
| `PublicResolutionIsSessionFree` | Public resolution does not require a signed-in browser session. |
| `PublicResolutionDoesNotMutateStore` | Resolving a public code does not change durable state. |
| `RestartPreservesDurableState` | Restart preserves active links, destinations, allocation history, and the next code. |
| `NoDeadlock` | Every reachable state has a next transition; the model does not get stuck. |

Together these cover the runtime, browser-session, and short-code regions plus the ten invariants in `statechart.md`. Password hashing, email normalization, cookie signing, exact form/error text, SQLite internals, process crashes, and the future Python implementation are intentionally outside this model.

## Passing result

The final clean run used the checked-in model and configuration with one TLC worker.

- Result: pass, exit code `0`.
- Behavioral states counted by the statechart runner: `81,825`.
- Rules passed: all rules listed above, including `NoDeadlock`.
- Chart output: the full graph exceeded the `/statechart` chart budget of 500 states, so no full `chart.mmd` was written. This does not affect the TLC invariant result; the checker still evaluated the rules.

## Deliberate broken variant

To prove that the verification can fail for a real defect, the temporary scratch change removed this guard from `RemoveGuard`:

```tla
/\ links[c].owner = sessions[b]
```

That guard is the model's owner authorization rule. With it removed, a signed-in account could remove any active code as long as the session and CSRF token were valid.

TLC found `MutationBoundary` broken. The shortest counterexample, translated into the application's terms, was:

| Step | Actor and action | Result |
| ---: | --- | --- |
| 0 | Application starts | Runtime is `Starting`; no links exist. |
| 1 | Configuration and database are ready | Runtime becomes `Serving`. |
| 2 | `browser-a` signs in as `alice` | Alice has a valid session and CSRF token. |
| 3 | `browser-b` signs in as `bob` | Bob has a separate valid session and CSRF token. |
| 4 | Bob creates a valid link | Code `1` becomes active and is owned by Bob. |
| 5 | Alice removes code `1` | The broken model accepts the removal even though Alice is not the owner. `MutationBoundary` fails. |

The raw TLC trace confirms the important state values at the failing step: code `1` has owner `bob`, the removing session is `alice`, and the response is `removed`.

The scratch change was then reverted. A clean rerun passed all rules again. No product implementation was changed during this negative test.

## How to reproduce

Read the current `/statechart` skill first. From a scratch directory outside the repository, run its current checker against:

- spec: `verification/url-shortener-statechart/LocalURLShortener.tla`;
- config: `verification/url-shortener-statechart/LocalURLShortener.cfg`;
- view: `verification/url-shortener-statechart/LocalURLShortenerView.ts`.

Write results to a new output directory outside the repository. The checked-in verification skill contains the rerun instructions and deliberately avoids hard-coding the installed launcher's path or options.

## Verification boundary

A passing result means: within this finite model, every behavior TLC explored preserved the stated rules. It does not mean:

- the unimplemented Python app is correct;
- arbitrary numbers of accounts, browsers, links, or destinations are covered;
- SQLite transactions or concurrent request linearization are correct;
- password, cookie, URL-parser, HTML, or configuration details are verified;
- crashes, recovery, backups, or filesystem corruption are verified.

When implementation begins, add Python conformance tests against the same transition oracle and rerun this model whenever the statechart or link-management semantics change. Use `/maintain-formal-verification-skill` to update the sync record after covered changes.

## Artifacts and sync

- Model: [`LocalURLShortener.tla`](./LocalURLShortener.tla)
- Config: [`LocalURLShortener.cfg`](./LocalURLShortener.cfg)
- Reader-facing view: [`LocalURLShortenerView.ts`](./LocalURLShortenerView.ts)
- Rerun skill: [`verify-url-shortener-statechart/SKILL.md`](../skills/verify-url-shortener-statechart/SKILL.md)
- Last verified model commit: `87725b0`
