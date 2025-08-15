#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-%REPO_URL_PLACEHOLDER%}"
APP_NAME="${APP_NAME:-mybot}"
INSTALL_DIR="/opt/${APP_NAME}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root (use: sudo bash <(curl -fsSL ${REPO_URL}/raw/main/install.sh))"
  exit 1
fi

# Basic deps
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y curl git unzip ca-certificates

# Detect OS (expect Ubuntu 22+)
source /etc/os-release || true
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Warning: not Ubuntu. Proceeding anyway..."
fi

# Prepare install dir
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [ ! -d ".git" ]; then
  echo "Cloning repo..."
  git init -q
  git remote add origin "${REPO_URL}.git" || true
  git fetch origin -q
  git checkout -q -B main origin/main
else
  echo "Updating repo..."
  git fetch origin -q
  git checkout -q -B main origin/main
fi

# Prepare env
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  echo "A default .env has been created at ${INSTALL_DIR}/.env (edit it before starting)."
fi

# Language-specific setup (Python/Node/PHP supported by run.sh)
# Python runtime (optional; only if Python detected)
if grep -q 'LANGUAGE="python"' run.sh; then
  apt-get install -y python3 python3-venv python3-pip
  if [ ! -d ".venv" ]; then
    python3 -m venv .venv
  fi
fi

# Node runtime (optional)
if grep -q 'LANGUAGE="node"' run.sh; then
  if ! command -v node >/dev/null 2>&1; then
    echo "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
  fi
fi

# PHP runtime (optional)
if grep -q 'LANGUAGE="php"' run.sh; then
  apt-get install -y php-cli
fi

# Systemd service
cat >/etc/systemd/system/${APP_NAME}.service <<SERVICE
[Unit]
Description=${APP_NAME} service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=-${INSTALL_DIR}/.env
ExecStart=${INSTALL_DIR}/run.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable ${APP_NAME}.service
echo "Installed. Edit ${INSTALL_DIR}/.env if needed, then start with: systemctl start ${APP_NAME} && systemctl status ${APP_NAME}"
