#!/usr/bin/env bash
set -euo pipefail

mkdir -p /root/.evilginx
if [ ! -f /root/.evilginx/config.json ]; then
  cp /usr/local/share/evilginx/config.default.json /root/.evilginx/config.json
fi

exec "$@"
