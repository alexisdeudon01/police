#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=".venv"

log() {
echo "$(date +'%Y-%m-%d %H:%M:%S') $*"
}

Load environment variables
if [ -f ".env" ]; then
log "Loading environment variables..."
set -o allexport
source .env
set +o allexport
else
log "WARNING: .env file not found"
fi

log "Checking Python installation..."
if ! command -v python3 >/dev/null; then
log "ERROR: python3 is not installed."
exit 1
fi

Create venv
if [ ! -d "$VENV_DIR" ]; then
log "Creating virtual environment..."
python3 -m venv "$VENV_DIR"
fi

Activate venv
shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
log "Using Python: $(python --version)"

Install dependencies
log "Installing requirements..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -e .

Check Docker
log "Checking Docker installation..."
if ! command -v docker >/dev/null; then
log "ERROR: Docker is not installed."
exit 1
fi

Build all images
log "Building Docker images..."
docker compose build

Start all services
log "Starting services..."
docker compose up -d

log "Bootstrap complete."

