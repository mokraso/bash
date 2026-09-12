#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# docker compose up -d --build
docker compose up -d
docker compose exec cus-ubuntu bash
