#!/bin/bash

set -e

export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# docker compose up -d --build
docker compose up -d
docker compose exec claude bash

