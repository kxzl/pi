---
name: git-workflow
description: Structured Git workflow for clean commit history, meaningful branch names, well-written PR descriptions, and changelog generation. Use when committing changes, creating branches, preparing a pull request, resolving merge conflicts, or generating a changelog from commit history. Enforces conventional commits format.
---

# Git Workflow

Structured, consistent Git practices for clean history and useful changelogs.

## Conventional Commits

All commits must follow this format:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

### Types

| Type | Use for |
|------|---------|
| `feat` | New feature visible to users |
| `fix` | Bug fix |
| `refactor` | Code restructuring with no behaviour change |
| `test` | Adding or updating tests |
| `perf` | Performance improvement |
| `docs` | Documentation only |
| `chore` | Build, tooling, dependency updates |
| `ci` | CI/CD pipeline changes |
| `style` | Formatting only (no logic change) |

### Scope

The scope is the area of the codebase affected — be specific:
- `feat(auth):` not `feat(backend):`
- `fix(csv-parser):` not `fix(utils):`
- `chore(deps):` for dependency bumps

### Breaking Changes

Add `!` after type/scope and a `BREAKING CHANGE:` footer:
```
feat(api)!: rename /users endpoint to /accounts

BREAKING CHANGE: All clients must update the base URL from /users to /accounts.
```

### Examples

```
feat(billing): add proration support for mid-cycle plan changes
fix(auth): prevent token refresh race condition on concurrent requests
refactor(db): extract query builder into separate module
test(payments): add integration tests for webhook retry logic
chore(deps): bump playwright from 1.40 to 1.42
docs(api): document rate limiting headers
perf(search): add composite index on (user_id, created_at)
```

## Branch Naming

```
<type>/<short-description>
<type>/<ticket-id>-<short-description>
```

Examples:
```bash
git checkout -b feat/user-notifications
git checkout -b fix/GH-123-null-pointer-on-logout
git checkout -b refactor/extract-payment-service
git checkout -b chore/upgrade-node-20
```

Rules:
- Lowercase, hyphens only — no underscores, no slashes in description
- Short (3–5 words max)
- Include ticket ID when one exists

## Before Committing

```bash
# Review exactly what you're about to commit
git diff --staged

# Make sure tests pass
# (use whatever the project's test command is)

# Stage selectively — never git add .
git add src/specific-file.ts
git add -p src/large-file.ts    # interactive hunk selection
```

## Writing a Good Commit Body

When the summary line isn't enough, add a body separated by a blank line:

```
fix(auth): prevent token refresh loop on 401 responses

Previously, a failed refresh would trigger another request that also
returned 401, causing an infinite loop that exhausted the token endpoint.

Now the client checks whether a refresh is already in-flight before
issuing a new one. Concurrent requests that receive 401 wait for the
shared refresh promise to resolve.

Fixes: #456
```

Rules for the body:
- Explain *why*, not *what* (the diff shows what)
- Wrap at 72 characters
- Reference issues/tickets in the footer

## PR Description Template

Use this structure for pull request descriptions:

```markdown
## Summary

- <One bullet per meaningful change>
- <Focus on the "why" and user-visible impact>

## Changes

- `path/to/file.ts` — what changed and why
- `path/to/other.ts` — what changed and why

## Test Plan

- [ ] Unit tests pass (`npm test`)
- [ ] Manual test: <describe the scenario>
- [ ] Edge case covered: <describe>

## Notes

<Any caveats, follow-up tickets, or things reviewers should pay attention to>
```

## Generating a Changelog

```bash
# All commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"- %s (%h)"

# Group by type for a structured changelog
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"%s" | node -e "
const lines = require('fs').readFileSync('/dev/stdin','utf8').trim().split('\n');
const groups = {};
for (const line of lines) {
  const m = line.match(/^(\w+)(\(.+?\))?!?:/);
  const type = m ? m[1] : 'other';
  (groups[type] = groups[type] || []).push(line);
}
const order = ['feat','fix','perf','refactor','docs','test','chore','ci'];
for (const type of [...order, ...Object.keys(groups).filter(t => !order.includes(t))]) {
  if (!groups[type]) continue;
  console.log('\n### ' + type);
  groups[type].forEach(l => console.log('- ' + l));
}
"

# Commits between two tags
git log v1.2.0..v1.3.0 --pretty=format:"- %s (%h)"
```

## Conflict Resolution

```bash
# See which files conflict
git status

# For each conflicted file, understand both sides before resolving
git diff --diff-filter=U          # show conflict markers
git log --merge --oneline         # commits that introduced the conflict

# After resolving, mark as resolved
git add <resolved-file>
git merge --continue              # or rebase --continue
```

Strategy:
1. Read both sides fully before choosing — don't just pick "ours"
2. If unsure which change is correct, check `git log -p <file>` to understand intent
3. After resolving, run tests before continuing the merge

## Undo / Fix Up

```bash
# Undo the last commit but keep changes staged
git reset --soft HEAD~1

# Amend the last commit message (before pushing)
git commit --amend -m "correct message"

# Unstage a file
git restore --staged <file>

# Discard local changes to a file
git restore <file>
```

## Useful Aliases to Suggest

```bash
# Pretty one-line log with graph
git log --oneline --graph --decorate

# Show what changed in the last N commits
git diff HEAD~3..HEAD

# Find which commit introduced a string
git log -S 'the exact string' --source --all
```
