FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# System dependencies
# --------------------------------------------------
RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        ca-certificates \
        build-essential \
        sudo \
        software-properties-common \
        vim \
        ripgrep \
        tree \
        xclip \
        python3 \
        python3-pip \
        pipx && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Node.js 22
# --------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# npm configuration
# --------------------------------------------------
RUN npm config delete omit && \
    npm config delete optional && \
    npm config set ignore-scripts false

# --------------------------------------------------
# Create non-root user
# --------------------------------------------------
ARG UID=1002
ARG GID=1002

RUN groupadd --gid ${GID} claude && \
    useradd \
        --uid ${UID} \
        --gid ${GID} \
        --create-home \
        --shell /bin/bash \
        claude && \
    usermod -aG sudo claude

# --------------------------------------------------
# Claude Code
# --------------------------------------------------
ARG CLAUDE_VERSION=2.1.237

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_VERSION}

# --------------------------------------------------
# Install Neovim
#
# Repo requires Neovim 0.11.1
# --------------------------------------------------
RUN add-apt-repository ppa:neovim-ppa/unstable && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Python tools
# --------------------------------------------------
RUN pipx ensurepath

USER claude

# --------------------------------------------------
# Neovim configuration
# --------------------------------------------------
RUN git clone https://github.com/lai-2/vim.git \
    /home/claude/.config/nvim

# --------------------------------------------------
# Claude config directory
# --------------------------------------------------
RUN mkdir -p /home/claude/.claude

WORKDIR /workspace

CMD ["/bin/bash"]
