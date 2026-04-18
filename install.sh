#!/usr/bin/env bash
set -euo pipefail

# --- Pi Agent Installer ---
# Builds the Docker image, configures shell alias, and sets up API keys.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="pi-agent"
ALIAS_MARKER="# [pi-agent-alias]"

# Colors
bold="\033[1m"
dim="\033[2m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
reset="\033[0m"

info()  { echo -e "${cyan}>>>${reset} $*"; }
ok()    { echo -e "${green}>>>${reset} $*"; }
warn()  { echo -e "${yellow}>>>${reset} $*"; }

# --- Detect shell rc file ---
detect_rc_file() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

RC_FILE="$(detect_rc_file)"

# --- Step 1: Build Docker image ---
info "Building Docker image ${bold}${IMAGE_NAME}${reset}..."
docker build \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"
ok "Image built."

# --- Step 2: Check Ollama ---
info "Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    model_count=$(curl -s http://localhost:11434/api/tags | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "0")
    if [ "$model_count" -eq 0 ]; then
        warn "Ollama is running but no models are installed."
        echo -e "    Recommended: ${bold}ollama pull qwen2.5-coder:32b${reset}"
        read -rp "    Pull qwen2.5-coder:32b now? [Y/n] " pull_model
        if [[ "${pull_model:-Y}" =~ ^[Yy]$ ]]; then
            ollama pull qwen2.5-coder:32b
        fi
    else
        ok "Ollama is running with $model_count model(s)."
    fi
else
    warn "Ollama is not running on localhost:11434."
    echo "    Install from https://ollama.com and pull a model:"
    echo "    ollama pull qwen2.5-coder:32b"
fi

# --- Step 3: API keys ---
info "Configuring API keys..."

# Kagi
existing_kagi=$(grep -oP 'export KAGI_API_KEY="\K[^"]*' "$RC_FILE" 2>/dev/null || true)
if [ -n "$existing_kagi" ]; then
    ok "Kagi API key already configured."
else
    echo ""
    echo -e "    ${bold}Kagi Search${reset} ${dim}(optional, for fast web search)${reset}"
    echo -e "    Get a key at: ${cyan}https://kagi.com/settings?p=api${reset}"
    read -rp "    Enter Kagi API key (or press Enter to skip): " kagi_key
    if [ -n "$kagi_key" ]; then
        # Remove any old KAGI_API_KEY line without the marker
        sed -i '/^export KAGI_API_KEY=/d' "$RC_FILE" 2>/dev/null || true
        echo "export KAGI_API_KEY=\"$kagi_key\"" >> "$RC_FILE"
        export KAGI_API_KEY="$kagi_key"
        ok "Kagi API key saved to $RC_FILE"
    else
        echo "    Skipped. You can add it later:"
        echo "    echo 'export KAGI_API_KEY=\"your-key\"' >> $RC_FILE"
    fi
fi

# --- Step 4: Shell alias ---
info "Configuring shell alias..."

ALIAS_LINE="alias pi='docker run -it --rm --network host -v \"\$(pwd):/workspace\" -v \"\$HOME/.pi:/home/piuser/.pi\" -e KAGI_API_KEY=\"\${KAGI_API_KEY}\" ${IMAGE_NAME}'"

if grep -qF "$ALIAS_MARKER" "$RC_FILE" 2>/dev/null; then
    # Update existing alias (marker line + next line)
    # Use awk to replace the line after the marker
    awk -v marker="$ALIAS_MARKER" -v alias_line="$ALIAS_LINE" '
        $0 == marker { print; getline; print alias_line; next }
        { print }
    ' "$RC_FILE" > "${RC_FILE}.tmp" && mv "${RC_FILE}.tmp" "$RC_FILE"
    ok "Updated existing pi alias in $RC_FILE"
else
    {
        echo ""
        echo "$ALIAS_MARKER"
        echo "$ALIAS_LINE"
    } >> "$RC_FILE"
    ok "Added pi alias to $RC_FILE"
fi

# --- Done ---
echo ""
echo -e "${green}${bold}Installation complete!${reset}"
echo ""
echo "    Restart your shell or run:"
echo -e "    ${bold}source $RC_FILE${reset}"
echo ""
echo "    Then start the agent from any project directory:"
echo -e "    ${bold}pi${reset}"
echo ""
echo -e "    Live browser: ${cyan}http://localhost:6080/vnc.html${reset}"
echo ""
