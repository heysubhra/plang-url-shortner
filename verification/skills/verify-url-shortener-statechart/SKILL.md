---
name: verify-url-shortener-statechart
description: "Formally check the local URL shortener lifecycle in docs/designs/statechart.md before changing startup, sessions, link ownership, short-code allocation, public resolution, restart persistence, or their implementation."
disable-model-invocation: false
---

# Verify the local URL shortener statechart

Use this skill when a change can alter the lifecycle promised by `docs/designs/statechart.md`: runtime startup or restart, sign-in/sign-out, CSRF-protected create/remove, owner-scoped listing, short-code allocation or retirement, public redirects/404s, or persistence of account/link state.

This repository currently contains the design and its verification model, not the planned Python/FastHTML application. The check therefore verifies the documented transition model. When the application is implemented, keep this model synchronized and add implementation conformance tests; a passing model check does not prove the Python code refines it.

## Property and harm

The property is: every reachable lifecycle state preserves runtime request gating, session-bound authorization and CSRF, owner-only link visibility/removal, one-time short-code allocation, correct public redirect/404 behavior, and durable link state across restart.

The harm prevented is a user being able to mutate another account's links, an old short URL redirecting to a later destination, a missing/removed code redirecting, or a restart silently losing or changing link ownership and destinations.

## Run the check

1. Read `/statechart` completely. It is the source of truth for the installed model-checking and charting command, its current options, and how to interpret `report.md`, `chart.mmd`, and counterexample paths.
2. Check `verification/url-shortener-statechart/LocalURLShortener.tla` with the adjacent `LocalURLShortener.cfg` and `LocalURLShortenerView.ts`, writing output to a new directory outside the repository. Use the command and options prescribed by the current `/statechart` skill; do not invent a replacement invocation.
3. Require a successful check with no invariant violations. Read every result through `/statechart`: its report and reader-facing chart are the authoritative explanation of any counterexample.

The model checker is TLA+/TLC because this target is a finite state machine with startup, sessions, requests, removal, and restart ordering. The constants are exhaustive for this model: two accounts, two browsers, two valid destinations, two invalid inputs, and three code slots. Three slots cover create → remove → create while keeping the rerun short. TLC uses the model's `View` to collapse only non-behavioral audit fields; it retains all state that can affect a future transition. The model has no random seed or sampled-run allowance.

## If the check fails

Treat the shortest path as a real finding first. Map its steps to the named transitions in `docs/designs/statechart.md`, then decide whether the design rule or the model is wrong. Do not weaken an invariant or alter the model merely to get a green run. If the design intentionally changes, update the statechart, model, config, view, and this skill together, rerun the check, and document the new scope.

If a future implementation exists, replay the counterexample against the real request path one transition at a time. A model failure that the implementation does not reproduce is evidence to inspect the model, not permission to ignore the result.

## Coverage and sync

The covered source is `docs/designs/statechart.md`, specifically its runtime, browser-session, and short-code regions; transition rules; and invariants 1–10. The executable artifacts are:

- `verification/url-shortener-statechart/LocalURLShortener.tla`
- `verification/url-shortener-statechart/LocalURLShortener.cfg`
- `verification/url-shortener-statechart/LocalURLShortenerView.ts`

The model abstracts away password hashing and regex details, email normalization, cookie signing, exact HTML/error text, SQLite internals, concurrent transaction linearization, process crashes, and the future Python implementation. Add focused tests or a conformance model for those boundaries when code exists.

Sync commit: `87725b0` (the commit whose model and configuration were confirmed by the final clean TLC run). Move this forward only after confirming that the verification still describes the covered statechart at the new commit.

After any change to the covered statechart or its transition semantics, use `/maintain-formal-verification-skill` to compare the sync commit, update the model and bounds if needed, rerun this skill, and only then advance the sync commit.
