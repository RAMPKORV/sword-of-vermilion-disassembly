#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/tools/server"
if [ ! -d node_modules ]; then
  npm install --silent
fi
node server.js
