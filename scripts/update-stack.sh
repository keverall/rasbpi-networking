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
# Reports results to the Prometheus Pushgateway so Grafana/Alertmanager can
# show the last outcome and the list of upgraded images, and alert on failure
# or a missed run.
#
set -uo pipefail

REPO_DIR="$HOME/repos/rasbpi-networking"
COMPOSE_DIR="$REPO_DIR/pi-hole"
LOG_FILE="$REPO_DIR/logs/update-stack.log"
PUSHGATEWAY="http://127.0.0.1:9091"
PGROUP="stack_update"
PINSTANCE="pi-networking"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"
}

# Snapshot currently-running container image IDs (name -> id) before the update.
snapshot_images() {
    docker ps --format '{{.Names}} {{.ID}}' | sort
}

# Push a set of metrics to the Pushgateway, replacing the whole grouping.
push_metrics() {
    local payload="$1"
    curl -sS --fail --max-time 10 \
        --data-binary "$payload" \
        "$PUSHGATEWAY/metrics/job/$PGROUP/instance/$PINSTANCE" \
        >>"$LOG_FILE" 2>&1 || log "WARN: failed to push metrics to Pushgateway"
}

# On any error, report failure to the Pushgateway and exit.
on_failure() {
    local rc=$?
    local step="${STEP:-unknown}"
    log "!!! Update FAILED at step: $step (exit $rc) !!!"
    local ts
    ts="$(date +%s)"
    push_metrics "stack_update_run_outcome{outcome=\"failure\",reason=\"$step\"} 1
stack_update_last_failure_ts $ts"
    exit "$rc"
}
trap 'on_failure' ERR

log "=== Starting weekly stack update ==="
STEP="git-pull"
cd "$COMPOSE_DIR"

log "Git pull origin/main"
git -C "$REPO_DIR" pull --ff-only origin main

STEP="snapshot"
BEFORE="$(snapshot_images)"

STEP="build"
log "Building local images"
docker compose build

STEP="pull"
log "Pulling upstream images"
docker compose pull

STEP="up"
log "Bringing stack up"
docker compose up -d

STEP="prune"
log "Pruning dangling images"
docker compose image prune -f >/dev/null 2>&1 || docker image prune -f

STEP="report"
AFTER="$(snapshot_images)"

# Diff BEFORE/AFTER image IDs per container to find what actually changed.
declare -A before_ids after_ids
while read -r name id; do before_ids["$name"]="$id"; done <<<"$BEFORE"
while read -r name id; do after_ids["$name"]="$id"; done <<<"$AFTER"

UPGRADED_LINES=""
for name in "${!after_ids[@]}"; do
    if [[ "${before_ids[$name]:-}" != "${after_ids[$name]}" ]]; then
        img="$(docker ps --filter "id=${after_ids[$name]}" --format '{{.Image}}' | head -1)"
        log "Upgraded: $name -> $img"
        UPGRADED_LINES="${UPGRADED_LINES}stack_update_image_upgraded{container=\"$name\",image=\"$img\"} 1"$'\n'
    fi
done

ts="$(date +%s)"
METRICS="stack_update_last_success_ts $ts
stack_update_run_outcome{outcome=\"success\"} 1
${UPGRADED_LINES}"
push_metrics "$METRICS"

log "=== Update complete ==="
