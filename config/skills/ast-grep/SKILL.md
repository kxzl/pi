---
name: ast-grep
description: Semantic code search and rewriting using AST patterns, not text. Use when you need to find all usages of a specific code construct (e.g. every async function, every useState call, every SQL query string), refactor a pattern across an entire codebase, or safely rename/transform code in a way that grep would miss due to whitespace or formatting differences. Supports JS, TS, Python, Rust, Go, Java, C, C++, and more.
---

# ast-grep (sg)

Structural search and replace using AST patterns. Matches code by structure, not text — whitespace, variable names, and formatting don't matter.

## Core Syntax

- `$VAR` — matches any single expression/node and captures it
- `$$$ARGS` — matches zero or more nodes (for argument lists, body statements, etc.)
- Literal code matches exactly

## Find Patterns

```bash
# All console.log calls
sg --pattern 'console.log($$$)' --lang js /workspace

# All await expressions
sg --pattern 'await $EXPR' --lang ts /workspace/src

# All useState hooks
sg --pattern 'const [$STATE, $SET] = useState($INIT)' --lang tsx /workspace

# All try/catch blocks
sg --pattern 'try { $$$BODY } catch ($ERR) { $$$HANDLER }' --lang js /workspace

# All arrow functions assigned to variables
sg --pattern 'const $NAME = ($$$PARAMS) => $$$BODY' --lang js /workspace

# Python: all function definitions
sg --pattern 'def $NAME($$$PARAMS): $$$BODY' --lang python /workspace

# Go: all error checks
sg --pattern 'if err != nil { $$$BODY }' --lang go /workspace

# Rust: all unwrap calls
sg --pattern '$EXPR.unwrap()' --lang rust /workspace
```

## Find and Rewrite

Use `-r` / `--rewrite` to replace matched patterns. Captured variables (`$VAR`, `$$$ARGS`) are available in the replacement.

```bash
# Replace console.log with a logger call
sg --pattern 'console.log($$$ARGS)' --rewrite 'logger.info($$$ARGS)' --lang js /workspace/src

# Remove unnecessary await on non-Promise
sg --pattern 'await Promise.resolve($VAL)' --rewrite '$VAL' --lang ts /workspace/src

# Rename a function across all files
sg --pattern 'getUserById($$$ARGS)' --rewrite 'findUserById($$$ARGS)' --lang ts /workspace/src

# Add error handling to bare fetch calls
sg --pattern 'fetch($URL)' --rewrite 'fetch($URL).catch(handleError)' --lang js /workspace
```

Add `--update-all` (or `-U`) to apply changes in-place without confirmation prompts:

```bash
sg --pattern 'console.log($$$)' --rewrite 'logger.debug($$$)' --lang js -U /workspace/src
```

## Run Config (for complex rules)

For multi-rule analysis, write a rule file:

```yaml
# /tmp/rule.yaml
id: no-direct-db-access
language: typescript
rule:
  pattern: 'db.query($$$)'
message: "Direct db.query() calls should go through the repository layer"
severity: warning
```

```bash
sg scan --rule /tmp/rule.yaml /workspace/src
```

## Count and Summarise

```bash
# Count matches per file
sg --pattern 'TODO($$$)' --lang ts /workspace | wc -l

# List only files that contain the pattern
sg --pattern 'any($$$)' --lang ts /workspace --json | node -e "
const chunks = [];
process.stdin.on('data', d => chunks.push(d));
process.stdin.on('end', () => {
  const matches = JSON.parse(chunks.join(''));
  const files = [...new Set(matches.map(m => m.file))];
  files.forEach(f => console.log(f));
});
"
```

## Language Identifiers

`js`, `ts`, `jsx`, `tsx`, `python`, `rust`, `go`, `java`, `c`, `cpp`, `cs`, `html`, `css`, `json`, `yaml`, `bash`

## Tips

- Run without `--rewrite` first to preview matches before applying changes
- Use `--json` output to pipe results to `jq` or Node for programmatic processing
- Patterns are whitespace-insensitive — `foo( $X )` matches `foo($X)`, `foo( $X )`  etc.
- Combine with `scc` to find the most complex files first, then target ast-grep there
