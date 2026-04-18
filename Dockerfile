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

# Install the Pi coding agent globally (as root so it goes to /usr/local/bin)
RUN npm install -g @mariozechner/pi-coding-agent

# Copy default config (host volume mount overrides at runtime)
RUN mkdir -p /home/piuser/.pi/agent
COPY --chown=piuser:piuser config/settings.json /home/piuser/.pi/agent/settings.json
COPY --chown=piuser:piuser config/models.json /home/piuser/.pi/agent/models.json

# Switch away from root to your matched user!
USER piuser
WORKDIR /workspace

# Set Pi as the default command
ENTRYPOINT ["pi"]
