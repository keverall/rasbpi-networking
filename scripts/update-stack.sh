#!/usr/bin/env bash
#
# Weekly Docker stack updater for pi-networking.
#
# Runs every Saturday via the systemd user timer (see update-stack.{service,timer}).
# Steps:
#   1. git pull the latest compose/config from origin/main
#   2. rebuild locally-built images (unbound, pihole, exporters)
#   3. pull upstream images (skips local images via pull_policy: build)
#   4. bring the stack up
#   5. prune dangling images
#
set -euo pipefail

REPO_DIR="$HOME/repos/rasbpi-networking"
COMPOSE_DIR="$REPO_DIR/pi-hole"
LOG_FILE="$REPO_DIR/logs/update-stack.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"
}

log "=== Starting weekly stack update ==="

cd "$COMPOSE_DIR"

log "Git pull origin/main"
git -C "$REPO_DIR" pull --ff-only origin main

log "Building local images"
docker compose build

log "Pulling upstream images"
docker compose pull

log "Bringing stack up"
docker compose up -d

log "Pruning dangling images"
docker image prune -f

log "=== Update complete ==="
