# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Custom Dockerized harness for the [Pi terminal coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) (`@mariozechner/pi-coding-agent`). Provides a secure container with Ollama local LLM support, Kagi web search, live Chromium browser, and bundled coding skills.

## Build & Run

```bash
# Automated install (builds image, configures alias, optional API keys)
./install.sh

# Or manually:
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pi-agent .
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$HOME/.pi:/home/piuser/.pi" \
  -e KAGI_API_KEY="${KAGI_API_KEY}" \
  pi-agent
```

## Architecture

- **Dockerfile**: `node:24-slim` base. Creates `piuser` matching host UID/GID. Installs: Pi agent, extension (`@0xkobold/pi-ollama`), `kagi-cli`, Playwright + Chromium, Mermaid CLI, `scc`, `duckdb`, `sg` (ast-grep). Copies config, tools, and skills into the image.
- **entrypoint.sh**: Starts Xvfb virtual display, x11vnc, noVNC (port 6080), headed Chromium with CDP (port 9222). Seeds bundled skills into `~/.pi/agent/skills/` on first run (preserves user edits). Then runs `pi`.
- **install.sh**: Build wizard — builds image, checks Ollama, prompts for Kagi API key, adds/updates shell alias (identified by `# [pi-agent-alias]` marker comment).
- **config/settings.json**: Default agent config baked into image. Ollama provider, optimized system prompt for small models, aggressive compaction. Overridden at runtime by `~/.pi/agent/settings.json`.
- **config/skills/**: Bundled skill definitions (browser, ast-grep, duckdb, scc, git-workflow, tdd, diagram, memory, browserbase).
- **tools/**: Node.js scripts for browser control (`browser.js`, `start-browser.js`), persistent memory (`memory.js`), Mermaid config.
- **`--network host`**: Required for Ollama access on `localhost:11434`.
- **Volume mounts**: `$(pwd):/workspace` for project files, `$HOME/.pi:/home/piuser/.pi` for persistent state.

## Key Design Constraints

- Container user (`piuser`) must match host UID/GID to avoid root-owned files.
- Host networking required for Ollama — do not switch to bridge networking.
- Extensions must be pre-installed as root in Dockerfile (`npm install -g`) because Pi's runtime package install runs as `piuser` and can't write to global node_modules.
- Ollama models are auto-discovered by `@0xkobold/pi-ollama` — no manual model list needed.
- System prompt is kept short (~200 words) for small local models. Uses explicit RULES and FORBIDDEN sections.
- Compaction is aggressive (reserveTokens: 4096, keepRecentTokens: 8000) for 8B models.
- The `# [pi-agent-alias]` marker in shell rc files allows `install.sh` to find and update the alias on re-runs.
