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

# Install virtual display, VNC tools, curl, and unzip for downloading binaries
RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install SCC (Sloc Cloc and Code) v3.7.0 — x86_64 Linux binary
RUN curl -sSL https://github.com/boyter/scc/releases/download/v3.7.0/scc_Linux_x86_64.tar.gz \
    | tar xz -C /usr/local/bin/ scc

# Install DuckDB CLI v1.5.2 — SQL over CSV/JSON/Parquet files, no server needed
RUN curl -sSL https://github.com/duckdb/duckdb/releases/download/v1.5.2/duckdb_cli-linux-amd64.zip \
    -o /tmp/duckdb.zip && \
    unzip -q /tmp/duckdb.zip -d /usr/local/bin/ && \
    chmod 755 /usr/local/bin/duckdb && \
    rm /tmp/duckdb.zip

# Install ast-grep (sg) v0.42.1 — AST-based semantic code search and rewriting
RUN curl -sSL https://github.com/ast-grep/ast-grep/releases/download/0.42.1/app-x86_64-unknown-linux-gnu.zip \
    -o /tmp/sg.zip && \
    unzip -j -q /tmp/sg.zip -d /usr/local/bin/ && \
    chmod 755 /usr/local/bin/sg && \
    rm /tmp/sg.zip

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

# Install Mermaid CLI for diagram rendering.
# PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD prevents a redundant Chromium download
# since the browser is already in PLAYWRIGHT_BROWSERS_PATH above.
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install -g @mermaid-js/mermaid-cli

# Copy default config (host volume mount overrides at runtime)
RUN mkdir -p /home/piuser/.pi/agent
COPY --chown=piuser:piuser config/settings.json /home/piuser/.pi/agent/settings.json

# Copy browser tools and startup script
COPY tools/browser.js /usr/local/lib/browser.js
COPY tools/start-browser.js /usr/local/lib/start-browser.js
COPY tools/memory.js /usr/local/lib/memory.js
COPY tools/mmdc-config.json /usr/local/lib/mmdc-config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Store bundled skills in a fixed image path (entrypoint seeds them into ~/.pi at runtime)
COPY config/skills/ /usr/local/share/pi-skills/

# Switch away from root to your matched user
USER piuser
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
