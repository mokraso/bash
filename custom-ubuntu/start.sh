#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# `cu 0` -> stop container (giữ nguyên data, chỉ biến mất khỏi `docker container ps`)
if [ "$1" = "0" ]; then
    docker compose stop
    exit 0
fi

# docker compose up -d --build
docker compose up -d
docker compose exec cnginx bash
