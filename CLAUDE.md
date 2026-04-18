# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Custom Dockerized harness for the [Pi terminal coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) (`@mariozechner/pi-coding-agent`). The goal is a secure, isolated container with advanced tool capabilities, local LLM support (Ollama), and browser automation.

## Build & Run

```bash
# Build the Docker image (passes host UID/GID to avoid root-owned files)
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pi-agent .

# Run (typically via the `pi` alias defined in ~/.bashrc)
docker run -it --rm --network host \
  -v "$(pwd):/workspace" \
  -v "$HOME/.pi:/home/piuser/.pi" \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  pi-agent
```

## Architecture

- **Dockerfile**: Builds a `node:24-slim` container, creates a `piuser` matching the host's UID/GID (to prevent file permission issues), and installs the Pi agent globally.
- **`--network host`**: Allows the container to reach local services like Ollama on `localhost:11434`.
- **Volume mounts**: `$(pwd):/workspace` for project files, `$HOME/.pi:/home/piuser/.pi` for persistent agent state/settings/skills across container restarts.
- **package.json**: Declares `@ollama/pi-web-search` as a dependency for web search tool support.
- **pi_agent_harness.md**: Design document covering architecture decisions, configuration state, and planned next steps (browser control, tool hardening, workflow automation).

## Key Design Constraints

- The container user (`piuser`) must match host UID/GID to avoid root-owned file locks on mounted volumes.
- Local LLM access (Ollama) requires host networking — do not switch to bridge networking without updating Ollama connectivity.
- Tools must be invoked via JSON tool-calling schemas, not as direct bash commands.
