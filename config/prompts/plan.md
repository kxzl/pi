---
description: "Plan before acting — read-only analysis, then a numbered step-by-step plan"
argument-hint: "<task description>"
---

I need you to PLAN, not execute.

**Task:** $@

**Instructions:**
1. Explore the relevant code using read, grep, find, ls, and bash (read-only commands only).
2. Do NOT edit or write any files yet.
3. After exploring, output a numbered plan with:
   - Each step as a concrete action (which file, what change, why)
   - Estimated risk per step (safe / needs-care / risky)
   - Any open questions or unknowns
4. Wait for my approval before executing any changes.
