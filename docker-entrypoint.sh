#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
set -e

CONFIG_FILE="${CONFIG_FILE:-/config/satellite1.conf}"

ARGS="--config $CONFIG_FILE"

if [ -n "${SOCKET_PATH}" ]; then
  ARGS="$ARGS --socket $SOCKET_PATH"
fi

if [ -n "${LOCK_FILE}" ]; then
  ARGS="$ARGS --lock-file $LOCK_FILE"
fi

# LOG_VERBOSITY: 0 (default, config decides), 1 (-v, INFO), 2 (-vv, DEBUG)
case "${LOG_VERBOSITY:-0}" in
  1) ARGS="$ARGS -v" ;;
  2) ARGS="$ARGS -vv" ;;
esac

# Run the agent by default; any other command (e.g. `sat1 --help`) runs unchanged.
if [ "$#" -eq 0 ]; then
  # First start: seed the config volume with the documented default configuration.
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "entrypoint: $CONFIG_FILE not found, writing the default configuration" >&2
    cp /app/default-satellite1.conf "$CONFIG_FILE"
  fi
  # shellcheck disable=SC2086
  exec sat-hardware-agent $ARGS
fi
exec "$@"
