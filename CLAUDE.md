# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Custom Dockerized harness for the [Pi terminal coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) (`@mariozechner/pi-coding-agent`). The goal is a secure, isolated container with local LLM support (Ollama) and web search.

## Build & Run

```bash
# Build the Docker image (passes host UID/GID to avoid root-owned files)
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pi-agent .

# Run (typically via the `pi` alias defined in ~/.bashrc)
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$HOME/.pi:/home/piuser/.pi" \
  pi-agent
```

## Architecture

- **Dockerfile**: Builds a `node:24-slim` container, creates a `piuser` matching the host's UID/GID, installs the Pi agent globally, and copies default config from `config/`.
- **`config/settings.json`**: Default agent configuration baked into the image. Sets Ollama as provider, gemma4:e4b as default model, system prompt optimized for small models, and aggressive compaction settings. Overridden at runtime by host's `~/.pi/agent/settings.json` via volume mount.
- **`@0xkobold/pi-ollama`**: Extension (installed via `packages` in settings.json) that auto-discovers Ollama models. No manual model list needed — just `ollama pull <model>` and it appears.
- **`--network host`**: Allows the container to reach Ollama on `localhost:11434`.
- **Volume mounts**: `$(pwd):/workspace` for project files, `$HOME/.pi:/home/piuser/.pi` for persistent agent state/settings/extensions across container restarts.
- **pi_agent_harness.md**: Design document covering architecture decisions and planned next steps.

## Key Design Constraints

- The container user (`piuser`) must match host UID/GID to avoid root-owned file locks on mounted volumes.
- Local LLM access (Ollama) requires host networking — do not switch to bridge networking without updating Ollama connectivity.
- Tools must be invoked via JSON tool-calling schemas, not as direct bash commands.
- Ollama models are auto-discovered by the `@0xkobold/pi-ollama` extension — no manual model list needed.
- The system prompt in `config/settings.json` is kept short (~150 words) because small local models have limited context windows. It uses explicit RULES and FORBIDDEN sections to prevent common mistakes (e.g., running tool names as bash commands).
- Compaction is aggressive (reserveTokens: 4096, keepRecentTokens: 8000) to keep 8B models focused.
- Tool count is limited to 9 (7 built-in + 2 web-search) — more tools degrade small model tool-calling accuracy.
