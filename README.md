# Pi Coding Agent (Dockerized)

A secure, isolated Docker harness for the [Pi terminal coding agent](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) with Ollama local LLM support, Kagi/Ollama web search, live browser control, and bundled coding skills.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Ollama](https://ollama.com) running on `localhost:11434`

## Install

```bash
git clone https://github.com/kxzl/pi.git && cd pi
./install.sh
```

The installer will:
- Ask for your Ollama host URL (default: `localhost`, or a remote IP)
- Build the Docker image (matching your host UID/GID)
- Pull a recommended Ollama model if none are installed
- Optionally configure your Kagi API key for web search
- Add the `pi` alias and `OLLAMA_HOST` export to your shell rc file
- Generate a `.env` file for docker-compose

After install, restart your shell or run `source ~/.bashrc`, then:

```bash
pi
```

## Manual Setup

If you prefer not to use the installer:

```bash
# Build
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pi-agent .

# Add to ~/.bashrc
export KAGI_API_KEY="your-key-here"  # optional
# [pi-agent-alias]
alias pi='docker run -it --rm --network host -v "$(pwd):/workspace" -v "$HOME/.pi:/home/piuser/.pi" -e KAGI_API_KEY="${KAGI_API_KEY}" pi-agent'

# Run
pi
```

## Remote Ollama

Run Pi on a laptop while Ollama stays on a more powerful desktop or server.

**On the machine running Ollama** — allow connections from the network:
```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

**On the machine running Pi** — point to the remote host:
```bash
# Option A: set once in your shell rc
export OLLAMA_HOST=http://192.168.1.x:11434

# Option B: override for a single session
OLLAMA_HOST=http://192.168.1.x:11434 pi
```

Or run `./install.sh` and enter the remote IP when prompted — it writes `OLLAMA_HOST` to your shell rc and `.env` automatically.

## Docker Compose

An alternative to the shell alias:

```bash
cp .env.example .env   # edit OLLAMA_HOST (and optionally KAGI_API_KEY)
docker compose build
docker compose run --rm pi
```

Override the host for a single session without editing `.env`:
```bash
OLLAMA_HOST=http://192.168.1.x:11434 docker compose run --rm pi
```

## How It Works

- Container runs as `piuser` matching your host UID/GID — no root-owned files
- `--network host` connects to Ollama on `localhost:11434`
- `$(pwd):/workspace` mounts your current project
- `$HOME/.pi` persists settings, sessions, skills, and extensions across runs

## Models

Ollama models are auto-discovered by the `@0xkobold/pi-ollama` extension. Pull any model and it appears in `/model` inside the agent.

```bash
ollama pull qwen2.5-coder:32b
```

Recommended models for coding (16GB VRAM):

| Model | Params | VRAM | Best For |
|-------|--------|------|----------|
| `gemma4:27b` | 26B MoE (4B active) | ~16GB | Agents, function calling |
| `qwen2.5-coder:32b` | 32B | ~22GB | Code generation, refactoring |
| `devstral` | 24B | ~15GB | Coding tasks |
| `qwen3:14b` | 14B | ~9GB | Fast, fits fully in VRAM |

Switch models interactively with `/model` or set `defaultModel` in `config/settings.json`.

## Web Search

Three tiers, fastest first:

1. **Kagi** (`kagi search "query"` via bash) — fast, high quality. Requires `KAGI_API_KEY` ([get one here](https://kagi.com/settings?p=api))
2. **Ollama web search** (`ollama_web_search` tool) — free, no API key needed
3. **Live browser** (via `/skill:browser`) — for JS-heavy pages, logins, forms

## Live Browser

The container runs headed Chromium on a virtual display. Watch the agent browse in real time:

1. Start `pi` as usual
2. Open **http://localhost:6080/vnc.html** in your host browser

The agent controls the browser via bash. See `/skill:browser` for full docs.

## Skills

Built-in skills (invoke with `/skill:<name>`):

| Skill | Description |
|-------|-------------|
| `browser` | Control live Chromium — navigate, click, fill forms, screenshot |
| `ast-grep` | AST-based semantic code search and rewriting |
| `duckdb` | SQL queries over CSV/JSON/Parquet files |
| `scc` | Code statistics (lines, complexity, languages) |
| `git-workflow` | Branching, commits, PR workflows |
| `tdd` | Test-driven development workflow |
| `diagram` | Generate diagrams with Mermaid |
| `memory` | Persistent key-value memory across sessions |
| `browserbase` | Cloud browser automation |

## Tools

Built-in: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`

Extensions (auto-installed):
- `ollama_web_search` / `ollama_web_fetch` — web search via Ollama
- `kagi` CLI — web search via Kagi (requires API key)

CLI tools in container: `scc`, `duckdb`, `sg` (ast-grep), `kagi`

## Configuration

Default config is in `config/settings.json`, baked into the image. At runtime, `~/.pi/agent/settings.json` overrides it (via volume mount).

Key settings:
- `defaultModel` — which Ollama model to use
- `systemPrompt` — instructions optimized for small local models
- `compaction` — auto-compresses context (aggressive defaults for 8B models)
- `packages` — Pi extensions to load
