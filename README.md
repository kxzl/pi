# Pi Coding Agent (Dockerized)

A secure, isolated Docker harness for the [Pi terminal coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) with Ollama local LLM support and web search.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Ollama](https://ollama.com) running on `localhost:11434`
- At least one model pulled:
  ```bash
  ollama pull gemma4:e4b
  ```

## Quick Start

```bash
# 1. Build the image (matches your host user to avoid root-owned files)
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pi-agent .

# 2. Add this alias to your ~/.bashrc (one-time)
alias pi='docker run -it --rm --network host -v "$(pwd):/workspace" -v "$HOME/.pi:/home/piuser/.pi" -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" pi-agent'

# 3. Run from any project directory
pi
```

## How It Works

- The container creates a `piuser` matching your host UID/GID so files it writes aren't root-owned
- `--network host` lets the agent talk to Ollama on `localhost:11434`
- `$(pwd):/workspace` mounts your current project directory
- `$HOME/.pi:/home/piuser/.pi` persists settings, sessions, and extensions across runs

## Models

The default model is `gemma4:e4b` (8B). Switch interactively with `/model` inside the agent.

| Model | Size | Good For |
|-------|------|----------|
| `gemma4:e4b` | 8B | Fast, simple tasks |
| `glm-4.7-flash` | 30B | Better reasoning, slower |

To add a new Ollama model:
1. Pull it: `ollama pull <model>`
2. Add `{ "id": "<model>" }` to the `models` array in `config/models.json`
3. Rebuild the image, or edit `~/.pi/agent/models.json` directly (no rebuild needed)

## Configuration

Default config lives in `config/` and is baked into the Docker image. At runtime, the host volume mount (`$HOME/.pi`) overrides it — edit files in `~/.pi/agent/` to customize without rebuilding.

Key settings:
- `defaultModel` — which Ollama model to use
- `systemPrompt` — instructions to keep small models on track
- `compaction` — auto-compresses context to keep small models focused
- `packages` — extensions to auto-install (currently: web search)

## Tools

Built-in: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`

From extensions:
- `ollama_web_search` — search the web via Ollama
- `ollama_web_fetch` — fetch and extract page content via Ollama
