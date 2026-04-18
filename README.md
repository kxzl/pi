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
alias pi='docker run -it --rm --network host -v "$(pwd):/workspace" -v "$HOME/.pi:/home/piuser/.pi" pi-agent'

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

Ollama models are auto-discovered by the `@0xkobold/pi-ollama` extension. Just pull a model with `ollama pull <model>` and it appears in `/model`.

## Configuration

Default config lives in `config/` and is baked into the Docker image. At runtime, the host volume mount (`$HOME/.pi`) overrides it — edit files in `~/.pi/agent/` to customize without rebuilding.

Key settings:
- `defaultModel` — which Ollama model to use
- `systemPrompt` — instructions to keep small models on track
- `compaction` — auto-compresses context to keep small models focused
- `packages` — extensions to auto-install (currently: Ollama integration + web search)

## Live Browser

The container runs a headed Chromium browser on a virtual display. Watch it live from your host:

1. Start the container as usual (`pi`)
2. Open **http://localhost:6080/vnc.html** in your host browser
3. You'll see the Chromium window — it updates in real time as the agent browses

The agent controls the browser via the `bash` tool:

```bash
# Navigate to a URL
node /usr/local/lib/browser.js '{"action":"navigate","url":"https://example.com"}'

# Take a screenshot (saved to /tmp/screenshot.png)
node /usr/local/lib/browser.js '{"action":"screenshot"}'

# Get visible page text
node /usr/local/lib/browser.js '{"action":"text"}'

# Click an element
node /usr/local/lib/browser.js '{"action":"click","selector":"button.submit"}'

# Fill an input
node /usr/local/lib/browser.js '{"action":"fill","selector":"#search","value":"hello"}'

# Run JavaScript
node /usr/local/lib/browser.js '{"action":"evaluate","script":"document.title"}'
```

Available actions: `navigate`, `screenshot`, `click`, `fill`, `evaluate`, `text`, `back`, `forward`

## Tools

Built-in: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`

From extensions:
- `ollama_web_search` — search the web via Ollama
- `ollama_web_fetch` — fetch and extract page content via Ollama
