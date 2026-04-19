---
description: "Review code for bugs, security issues, and improvements"
argument-hint: "<file or directory>"
---

Review the code in `$1` for:

1. **Bugs** — Logic errors, edge cases, off-by-one, null/undefined risks
2. **Security** — Injection, path traversal, secrets exposure, unsafe inputs
3. **Performance** — Unnecessary loops, missing early returns, N+1 patterns
4. **Readability** — Confusing names, missing context, overly clever code

For each finding:
- Quote the relevant line(s)
- Explain the issue
- Suggest a fix (code snippet if helpful)

Skip nitpicks about style or formatting. Focus on things that could break.
