---
description: "Review staged/unstaged changes and prepare a pull request"
argument-hint: "[base-branch]"
---

Review my current changes and help me prepare a pull request.

1. Run `git diff` and `git diff --cached` to see all changes.
2. Run `git log --oneline -10` for recent commit style.
3. If a base branch is specified, also run `git diff ${1:-main}...HEAD`.
4. Summarize what changed and why (infer purpose from the diff).
5. Draft a PR title (under 70 chars) and body with:
   - **Summary**: 2-3 bullet points
   - **Changes**: file-by-file breakdown
   - **Testing**: suggested test plan
6. Show the draft and wait for my feedback before creating the PR.
