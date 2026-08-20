FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        ca-certificates \
        npm \
        nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Default working directory
WORKDIR /workspace

# Start bash
CMD ["/bin/bash"]
