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

exec pi "$@"
