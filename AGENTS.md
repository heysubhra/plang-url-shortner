# Project Agent Instructions

## Git workflow

Use the Git terminal for repository operations in this project. The GitHub remote is:

```text
https://github.com/heysubhra/plang-url-shortner.git
```

For normal changes:

```sh
git status
git add <files>
git commit -m "<message>"
git push
```

Do not use the GitHub API integration as a substitute for the Git terminal when committing or pushing project changes. Keep `.env`, local SQLite databases, virtual environments, and generated Python files out of version control.

## Model-first verification

Before implementing product behavior, document the requirements and design, then use PeasyAI/P to model the critical state transitions and invariants as P state machines. Compile and run PChecker model checking before coding against that design. Keep the verified P model as the behavioral reference for implementation.

PChecker verifies the P model; it does not directly prove that a separate Python implementation is correct. For the Python app, add conformance tests that exercise the implementation against the model's expected transitions and outcomes. Do not describe the Python code as formally verified unless a separate refinement/proof method establishes that connection. Keep the model and tests in sync when requirements change.
