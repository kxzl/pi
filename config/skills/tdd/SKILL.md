---
name: tdd
description: Enforce strict Test-Driven Development. Use when asked to implement a feature, fix a bug, or add functionality to a project with a test suite. Follows red-green-refactor: write a failing test first, confirm it fails, then write the minimum code to pass it, then clean up. Prevents writing implementation before tests.
---

# TDD Enforcer

Strict red-green-refactor workflow. Do not skip steps.

## The Three Rules

1. **You may not write production code unless it is to make a failing test pass.**
2. **You may not write more of a test than is sufficient to fail.**
3. **You may not write more production code than is sufficient to make the failing test pass.**

## Workflow

### Step 0 — Understand the requirement

Before writing anything:
- Read the requirement carefully
- Identify the smallest testable unit of behaviour
- State it as a one-sentence assertion: _"Given X, when Y, then Z"_

### Step 1 — RED: Write a failing test

Write the smallest test that captures the requirement. The test must:
- Be specific (one assertion per test when possible)
- Call code that does not exist yet (or fails)
- Have a name that describes the behaviour: `test('returns empty array when input is empty', ...)`

Run the test suite and **confirm it fails**. If it passes without implementation, the test is wrong.

```bash
# Examples — use whatever runner the project uses:
npx jest --testPathPattern=<file>
npx vitest run <file>
python -m pytest <file>::<test>
go test ./... -run <TestName>
cargo test <test_name>
```

Expected output: one new failure. If more tests fail, you've broken something — stop and investigate.

### Step 2 — GREEN: Write minimum implementation

Write **only enough production code to make the failing test pass**. Resist the urge to generalise.

- Hard-coding a return value to pass the test is fine at this stage
- Do not add logic for cases not yet tested
- Run the full suite and confirm **all tests pass**

If you introduce a regression (other tests now fail), fix it before proceeding.

### Step 3 — REFACTOR: Clean up

With a green test suite as a safety net:
- Remove duplication
- Improve names
- Simplify logic
- Extract abstractions only when the pattern appears three times

Run the full suite again after every change. **Do not refactor while red.**

### Repeat

Go back to Step 1 for the next requirement. Each cycle should take minutes, not hours.

## Micro-step Pattern (for complex features)

Break large requirements into a sequence of small increments:

```
Requirement: "Parse a CSV string into rows of objects"

Cycle 1: empty string → []
Cycle 2: one header row → [{header: true, ...}]  
Cycle 3: one data row  → [{col1: "val", col2: "val"}]
Cycle 4: multiple rows
Cycle 5: quoted fields with commas inside
Cycle 6: escaped quotes
```

Each cycle is a complete red-green-refactor loop.

## Rules for Bug Fixes

1. Write a test that **reproduces the bug** and fails
2. Confirm it fails (proving the bug exists)
3. Fix the bug
4. Confirm the test passes
5. Confirm no regressions

Never fix a bug without a test. If you can't write a test that fails, you don't understand the bug.

## What to Do When Stuck

- **Test is hard to write** → the design is too coupled; refactor the interface first
- **Too many things to test at once** → break the requirement into smaller increments
- **Not sure what to test** → write the assertion you wish were true, then make it so
- **Test requires too much setup** → extract a pure function and test that instead
