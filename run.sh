#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/src"

# Load env if present
if [ -f "../.env" ]; then
  set -a
  source "../.env"
  set +a
fi

LANGUAGE="php"

if [ "$LANGUAGE" = "python" ]; then
  # Activate venv if exists
  if [ -f "../.venv/bin/activate" ]; then
    source "../.venv/bin/activate"
  fi
  # Install deps if requirements.txt exists
  if [ -f "requirements.txt" ]; then
    python3 -m pip install --upgrade pip >/dev/null || true
    python3 -m pip install -r requirements.txt
  fi
  # Choose entrypoint
  ENTRY="bot.php"
  if [ -z "$ENTRY" ]; then
    # try to find a .py with common names
    for c in bot.py main.py app.py server.py; do
      if [ -f "$c" ]; then ENTRY="$c"; break; fi
    done
    # fallback to first .py at repo root
    if [ -z "$ENTRY" ]; then
      ENTRY="$(ls -1 *.py 2>/dev/null | head -n1 || true)"
    fi
  fi
  if [ -z "$ENTRY" ]; then
    echo "Could not find a Python entrypoint. Please set ENTRY manually in run.sh"
    exit 1
  fi
  exec python3 "$ENTRY"
elif [ "$LANGUAGE" = "node" ]; then
  if [ -f "package.json" ]; then
    npm install
    # Prefer npm start
    npm run start --if-present || node index.js
  else
    # fallback to common names
    for f in index.js server.js bot.js; do
      if [ -f "$f" ]; then exec node "$f"; fi
    done
    echo "No package.json or common Node entrypoint found."
    exit 1
  fi
elif [ "$LANGUAGE" = "php" ]; then
  # Try to run a long-lived PHP script
  for f in bot.php server.php index.php; do
    if [ -f "$f" ]; then exec php "$f"; fi
  done
  echo "No PHP entrypoint found."
  exit 1
else
  echo "Language not detected automatically. Please customize run.sh"
  exit 1
fi
