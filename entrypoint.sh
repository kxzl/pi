#!/bin/bash
set -e

# Start virtual X display (1920x1080, 24-bit colour)
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
sleep 1

# VNC server sharing the virtual display (no password — local dev only)
x11vnc -display :99 -forever -nopw -quiet &

# noVNC web UI at port 6080 — accessible at http://localhost:6080/vnc.html
websockify --web /usr/share/novnc 6080 localhost:5900 &
sleep 0.5

# Launch headed Chromium with CDP on port 9222
node /usr/local/lib/start-browser.js &

# Wait up to 10s for the CDP endpoint to be ready
node -e "
const http = require('http');
let tries = 20;
const check = () => {
  http.get('http://localhost:9222/json', () => process.exit(0))
      .on('error', () => { if (--tries <= 0) process.exit(1); setTimeout(check, 500); });
};
check();
" && echo "Live browser: http://localhost:6080/vnc.html" \
  || echo "Warning: browser CDP not ready; browser tool may fail"

# Seed bundled skills into ~/.pi/agent/skills/ on first run.
# Only copies skills that don't already exist, so user edits are preserved.
for skill_src in /usr/local/share/pi-skills/*/; do
  skill_name=$(basename "$skill_src")
  skill_dest="/home/piuser/.pi/agent/skills/$skill_name"
  if [ ! -d "$skill_dest" ]; then
    mkdir -p "$skill_dest"
    cp -r "$skill_src"* "$skill_dest/"
  fi
done

exec pi "$@"
