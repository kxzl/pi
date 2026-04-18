# Use the lightweight Node 24 image
FROM node:24-slim

# Accept the host's UID and GID as build arguments
ARG UID=1000
ARG GID=1000

# Remove the default 'node' user to prevent ID clashes
RUN userdel -r node || true

# Create a user named 'piuser' matching your host system's IDs
RUN groupadd -g ${GID} piuser && \
    useradd -u ${UID} -g ${GID} -m -s /bin/bash piuser

# Install virtual display and VNC tools for live browser support
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

# Install the Pi coding agent globally (as root so it goes to /usr/local/bin)
RUN npm install -g @mariozechner/pi-coding-agent

# Install Playwright and download Chromium with all required system dependencies.
# PLAYWRIGHT_BROWSERS_PATH puts binaries in a world-readable location.
# NODE_PATH lets scripts require('playwright') without a local node_modules.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
ENV NODE_PATH=/usr/local/lib/node_modules
RUN npm install -g playwright && \
    playwright install --with-deps chromium && \
    chmod -R 755 /opt/playwright-browsers

# Copy default config (host volume mount overrides at runtime)
RUN mkdir -p /home/piuser/.pi/agent
COPY --chown=piuser:piuser config/settings.json /home/piuser/.pi/agent/settings.json

# Copy browser tools and startup script
COPY tools/browser.js /usr/local/lib/browser.js
COPY tools/start-browser.js /usr/local/lib/start-browser.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch away from root to your matched user
USER piuser
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
