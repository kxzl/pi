---
name: scc
description: Instantly measure codebase size and complexity with SCC (Sloc Cloc and Code). Use at the start of any session to understand language breakdown, file counts, line counts, and cyclomatic complexity before diving in. Also useful for tracking complexity growth during refactoring or comparing before/after metrics.
---

# SCC — Sloc Cloc and Code

Fast, accurate codebase statistics: languages, line counts, blank/comment ratios, and complexity.

## Quick Start

```bash
# Full project summary
scc /workspace

# JSON output (easier for the agent to parse)
scc --format json /workspace

# Sort by lines of code
scc --sort lines /workspace

# Specific directory or file type
scc /workspace/src
scc --include-ext ts,tsx /workspace
```

## Useful Flags

| Flag | Purpose |
|------|---------|
| `--format json` | Machine-readable JSON output |
| `--sort lines` | Sort results by line count |
| `--sort complexity` | Sort by cyclomatic complexity |
| `--include-ext ts,js` | Limit to specific extensions |
| `--exclude-dir node_modules,dist` | Skip directories |
| `--no-complexity` | Skip complexity calculation (faster) |
| `--count-as yaml:yml` | Treat `.yml` files as YAML |
| `-w` | Show results per-file |

## Workflow: Session Orientation

Run this at the start of a session to understand what you're working with:

```bash
scc --format json /workspace
```

Parse the JSON to answer:
- What languages are in use and in what proportion?
- How many total lines of actual code (vs comments/blanks)?
- Which files are the most complex?
- Are there unexpected file types?

## Workflow: Complexity Hotspots

```bash
# Find the most complex files
scc --sort complexity --format json /workspace
```

High complexity scores (>15 per file) indicate candidates for refactoring. Use this to focus code review or testing effort.

## Workflow: Track Refactoring Progress

```bash
# Before refactoring — save baseline
scc --format json /workspace > /tmp/scc-before.json

# After refactoring
scc --format json /workspace > /tmp/scc-after.json

# Compare
node -e "
const before = require('/tmp/scc-before.json');
const after  = require('/tmp/scc-after.json');
const b = before.reduce((s,l) => ({lines: s.lines+l.Code, complexity: s.complexity+l.Complexity}), {lines:0,complexity:0});
const a = after.reduce((s,l)  => ({lines: s.lines+l.Code, complexity: s.complexity+l.Complexity}), {lines:0,complexity:0});
console.log('Lines:', b.lines, '->', a.lines, '(', a.lines-b.lines, ')');
console.log('Complexity:', b.complexity, '->', a.complexity, '(', a.complexity-b.complexity, ')');
"
```

## Output Fields (JSON mode)

Each entry in the JSON array represents one language:
- `Name` — language name
- `Files` — number of files
- `Lines` — total lines
- `Code` — lines of actual code
- `Comment` — comment lines
- `Blank` — blank lines
- `Complexity` — sum of cyclomatic complexity across all files
- `WeightedComplexity` — complexity normalized by lines
