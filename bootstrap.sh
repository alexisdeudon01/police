#!/usr/bin/env bash
set -euo pipefail

log() { echo "[BOOTSTRAP] $*"; }

# Load .env
if [ -f ".env" ]; then
  set -o allexport
  source .env
  set +o allexport
fi

# Check Python
log "Checking Python..."
command -v python3 >/dev/null || { log "python3 missing"; exit 1; }

VENV_DIR=".venv"

# Create venv
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

# Activate
source "$VENV_DIR/bin/activate"

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -e .

# Check Docker
log "Checking Docker..."
command -v docker >/dev/null || { log "Docker missing"; exit 1; }

# Build & start containers
log "Building with docker compose..."
docker compose build

log "Starting services..."
docker compose up -d

log "Bootstrap finished."
