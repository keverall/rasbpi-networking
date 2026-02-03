#!/bin/sh
set -eu

CONF_DIR="/opt/unbound/etc/unbound"
DEV_DIR="$CONF_DIR/dev"
VAR_DIR="$CONF_DIR/var"

echo "[entrypoint] wrapper starting" >&2

mkdir -p "$CONF_DIR"

echo "[entrypoint] ensure ownership of mounted config is correct (chown -R _unbound:_unbound)" >&2
# Attempt to fix ownership of host-mounted config so the _unbound user inside the
# container can read keys and write var files. Fail startup if chown fails,
# because incorrect ownership will cause silent runtime errors (exporters unable
# to access certificates/control files). This makes the problem explicit.
if ! chown -R _unbound:_unbound "$CONF_DIR" 2>/dev/null; then
  echo "[entrypoint] ERROR: failed to chown $CONF_DIR to _unbound:_unbound; aborting" >&2
  exit 1
fi

if [ ! -d "$DEV_DIR" ]; then
  echo "[entrypoint] creating $DEV_DIR and copying /dev files" >&2
  mkdir -p "$DEV_DIR"
  cp -a /dev/random /dev/urandom /dev/null "$DEV_DIR" 2>/dev/null || true
fi

echo "[entrypoint] ensuring $VAR_DIR exists" >&2
mkdir -p -m 700 "$VAR_DIR"
chown _unbound:_unbound "$VAR_DIR" 2>/dev/null || true

if [ -x /opt/unbound/sbin/unbound-anchor ]; then
  echo "[entrypoint] running unbound-anchor to (re)generate root.key if needed" >&2
  /opt/unbound/sbin/unbound-anchor -a "$VAR_DIR/root.key" || true
fi

echo "[entrypoint] exec unbound in foreground (stderr->stdout, verbose)" >&2
# Run unbound in foreground and redirect stderr to stdout so Docker captures all output
exec /opt/unbound/sbin/unbound -d -v -c "$CONF_DIR/unbound.conf" 2>&1
