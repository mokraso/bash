FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# System dependencies
# --------------------------------------------------
RUN apt-get update && \
    apt-get install -y \
        curl \
        vim \
        neovim \
        git \
        ca-certificates \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Node.js 22
# --------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Verify Node.js and npm
RUN node --version && \
    npm --version

# --------------------------------------------------
# npm configuration
# --------------------------------------------------
RUN npm config delete omit && \
    npm config delete optional && \
    npm config set ignore-scripts false

# --------------------------------------------------
# Claude Code
# --------------------------------------------------
ARG CLAUDE_VERSION=2.1.237

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_VERSION}

# --------------------------------------------------
# Verify Claude Code installation
# --------------------------------------------------
RUN claude --version

RUN echo "alias cc='claude --dangerously-skip-permissions'" >> ~/.bashrc

# --------------------------------------------------
# Workspace
# --------------------------------------------------
WORKDIR /workspace

CMD ["/bin/bash"]
