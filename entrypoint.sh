#!/bin/bash
set -e

# ── Start background services (suppress noisy output) ──────────────────────

# Virtual X display
Xvfb :99 -screen 0 1920x1080x24 >/dev/null 2>&1 &
export DISPLAY=:99
sleep 1

# VNC server
x11vnc -display :99 -forever -nopw -quiet >/dev/null 2>&1 &

# noVNC web UI
websockify --web /usr/share/novnc 6080 localhost:5900 >/dev/null 2>&1 &
sleep 0.5

# Headed Chromium with CDP
node /usr/local/lib/start-browser.js >/dev/null 2>&1 &

# Wait up to 10s for CDP
BROWSER_OK=false
node -e "
const http = require('http');
let tries = 20;
const check = () => {
  http.get('http://localhost:9222/json', () => process.exit(0))
      .on('error', () => { if (--tries <= 0) process.exit(1); setTimeout(check, 500); });
};
check();
" 2>/dev/null && BROWSER_OK=true

# ── Seed bundled skills ─────────────────────────────────────────────────────

for skill_src in /usr/local/share/pi-skills/*/; do
  skill_name=$(basename "$skill_src")
  skill_dest="/home/piuser/.pi/agent/skills/$skill_name"
  if [ ! -d "$skill_dest" ]; then
    mkdir -p "$skill_dest"
    cp -r "$skill_src"* "$skill_dest/"
  fi
done

# ── Banner ──────────────────────────────────────────────────────────────────

# Collect skill names from seeded skills directory
SKILLS=""
if [ -d "$HOME/.pi/agent/skills" ]; then
  for s in "$HOME/.pi/agent/skills"/*/; do
    [ -d "$s" ] || continue
    name=$(basename "$s")
    SKILLS="${SKILLS}  /skill:${name}\n"
  done
fi

# Pick a random motivational quote
QUOTES=(
  "I'm not a robot. I'm a mass of bugs holding a keyboard."
  "It works on my machine. And my machine is this container."
  "sudo make me a sandwich. Also, fix that segfault."
  "99 little bugs in the code, 99 little bugs... patch one down, compile around — 127 little bugs in the code."
  "There are only two hard problems: cache invalidation, naming things, and off-by-one errors."
  "My code doesn't have bugs. It has surprise features."
  "In theory, theory and practice are the same. In practice, they're not."
  "A good programmer looks both ways before crossing a one-way street."
  "The best thing about a boolean is that even if you're wrong, you're only off by a bit."
  "Debugging: being the detective in a crime movie where you are also the murderer."
)
QUOTE="${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"

echo ""
echo "  π agent harness"
echo "  \"${QUOTE}\""

echo ""
echo "  Tools:  read, write, edit, bash, grep, find, ls"
echo "          ollama_web_search, ollama_web_fetch"
echo ""
echo "  Skills:"
if [ -n "$SKILLS" ]; then
  echo -e "$SKILLS"
else
  echo "    (none found)"
fi
echo "  URLs:"
if [ "$BROWSER_OK" = true ]; then
  echo "    Browser (VNC):  http://localhost:6080/vnc.html"
  echo "    Browser (CDP):  http://localhost:9222"
else
  echo "    Browser: not ready (CDP failed to start)"
fi
echo "    Ollama:         http://localhost:11434"
echo ""

exec pi "$@"
