Project Context: Custom Dockerized "Pi" AI Harness

Goal: Build a highly customized, secure, and isolated Docker container for the Pi terminal coding agent (@mariozechner/pi-coding-agent) with advanced tool capabilities, local model support, and browser automation.
1. Architectural Decisions Made So Far

    Base Environment: Transitioned from a bare-metal Linux installation to an isolated Docker setup using node:24-slim.

    Networking: Using --network host so the containerized agent can seamlessly communicate with local LLMs (like Ollama running on localhost:11434).

    Permission Management (Crucial): To prevent root-owned file locks on the Linux host, the container is built dynamically using the host's UID and GID. A custom piuser is created inside the container to match the host user.

    Volume Mounts: * $(pwd):/workspace: Gives the agent access to edit the current project directory.

        $HOME/.pi:/home/piuser/.pi: Persists agent state, skills, extensions, and settings across container reboots.

2. Host System Configuration (~/.bashrc)

To make the ephemeral Docker container feel like a native CLI tool, we modified the host's ~/.bashrc file to handle environment variables and execution.

Alias and Environment Setup:
Bash

# Export API keys for cloud models (if stepping up from local Ollama)
export ANTHROPIC_API_KEY="your-anthropic-key-here"

# The core execution alias
# - Runs interactively, removes container on exit
# - Bridges to host network for Ollama access
# - Maps current working directory to /workspace
# - Maps persistent .pi configuration to the matched user's home
# - Passes API keys through to the container
alias pi='docker run -it --rm --network host -v "$(pwd):/workspace" -v "$HOME/.pi:/home/piuser/.pi" -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" pi-agent'

3. Current Working Dockerfile (Playwright/Browser Ready)

We are currently balancing the need for browser control with the constraints of a headless Docker container. Here is the latest planned Dockerfile structure:
Dockerfile

FROM node:24-slim

# Accept host UID/GID
ARG UID=1000
ARG GID=1000

# Remove default node user and add matched host user
RUN userdel -r node || true
RUN groupadd -g ${GID} piuser && useradd -u ${UID} -g ${GID} -m -s /bin/bash piuser

# (Optional) Install Linux GUI dependencies for local Playwright browser control
# RUN apt-get update && apt-get install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 xvfb && rm -rf /var/lib/apt/lists/*

# Install Pi agent globally
RUN npm install -g @mariozechner/pi-coding-agent

USER piuser
WORKDIR /workspace
ENTRYPOINT ["pi"]

4. Configuration State (settings.json)

Because smaller local models (like gemma4:e4b) struggled with JSON tool-calling and hallucinated bash commands, we enforced strict system prompts. We are now transitioning to more capable models (like Claude 3.7 Sonnet or Qwen 2.5 Coder) for complex autonomous tasks:
JSON

{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-3-7-sonnet-latest",
  "tools": ["read", "write", "edit", "bash", "grep", "find", "ls", "web_search"],
  "systemPrompt": "You are an elite autonomous AI developer in a terminal harness. You have access to tools via JSON tool-calling. NEVER run tool names (like pi-web-search) directly in the bash terminal. Use proper tool schemas."
}

5. Next Steps / Current Focus for the Agent

I need you to help me finalize this "flavor" of the harness. Specifically, we need to focus on:

    Browser Control Integration: Finalizing the best way to give the agent web-browsing capabilities (either via cloud extensions like Steel or finishing the MCP Playwright local installation).

    Tool Hardening: Ensuring extensions like @ollama/pi-web-search are perfectly mapped and usable by the LLM.

    Workflow Automation: Building custom tools/skills that allow the agent to run tests and analyze results within this Docker boundary.
