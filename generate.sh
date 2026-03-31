#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[SETUP] $*"
}

ROOT_DIR="$(pwd)"

log "Starting full stack setup..."

# ---------------------------------------------------------
# 1. Create directory structure
# ---------------------------------------------------------
log "Creating service directories..."

mkdir -p database
mkdir -p dashboard
mkdir -p orchestrator
mkdir -p .github/workflows

# ---------------------------------------------------------
# 2. Create .env file (only if missing)
# ---------------------------------------------------------
if [ ! -f ".env" ]; then
  cat > .env <<EOF
DB_USER=admin
DB_PASSWORD=secret
DB_NAME=appdb
DB_PORT=5432

DASHBOARD_PORT=8080
EOF
  log ".env file created."
else
  log ".env already exists. Skipping."
fi

# Load .env values for use below
set -o allexport
source .env
set +o allexport

if [ -n "${DATABASE_URL:-}" ]; then
  DB_URI_NO_SCHEME="${DATABASE_URL#*://}"
  DB_CREDS="${DB_URI_NO_SCHEME%@*}"
  DB_HOST_AND_PATH="${DB_URI_NO_SCHEME#*@}"

  DB_USER="${DB_USER:-${DB_CREDS%%:*}}"
  DB_PASSWORD="${DB_PASSWORD:-${DB_CREDS#*:}}"

  DB_PORT_FROM_URL="$(echo "$DB_HOST_AND_PATH" | sed -E 's|^[^:]+:([0-9]+)/.*$|\1|')"
  DB_NAME_FROM_URL="$(echo "$DB_HOST_AND_PATH" | sed -E 's|^[^/]+/(.+)$|\1|')"

  DB_PORT="${DB_PORT:-${DB_PORT_FROM_URL}}"
  DB_NAME="${DB_NAME:-${DB_NAME_FROM_URL}}"
fi

DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-secret}"
DB_NAME="${DB_NAME:-appdb}"
DB_PORT="${DB_PORT:-5432}"
DASHBOARD_PORT="${DASHBOARD_PORT:-8080}"

# ---------------------------------------------------------
# 3. Generate Dockerfile: DATABASE
# ---------------------------------------------------------
cat > database/Dockerfile <<EOF
FROM postgres:16

ENV POSTGRES_USER=${DB_USER}
ENV POSTGRES_PASSWORD=${DB_PASSWORD}
ENV POSTGRES_DB=${DB_NAME}

EXPOSE 5432
EOF

log "Database Dockerfile created."

# ---------------------------------------------------------
# 4. Generate Dockerfile: DASHBOARD
# ---------------------------------------------------------
cat > dashboard/requirements.txt <<EOF
fastapi
uvicorn
EOF

cat > dashboard/main.py <<EOF
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def home():
    return {"status": "dashboard running"}
EOF

cat > dashboard/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

log "Dashboard Dockerfile created."

# ---------------------------------------------------------
# 5. Generate Dockerfile: ORCHESTRATOR
# ---------------------------------------------------------
cat > orchestrator/requirements.txt <<EOF
-r ../requirements.txt
EOF

cat > orchestrator/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY ai_engine /app/ai_engine
COPY pyproject.toml /app/
COPY setup.cfg /app/
COPY setup.py /app/

CMD ["python", "-m", "ai_engine.orchestration.executor"]
EOF

log "Orchestrator Dockerfile created."

# ---------------------------------------------------------
# 6. Create docker-compose.yml
# ---------------------------------------------------------
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  database:
    build: ./database
    container_name: db_container
    env_file: .env
    ports:
      - "${DB_PORT}:5432"

  dashboard:
    build: ./dashboard
    container_name: dashboard_container
    env_file: .env
    ports:
      - "${DASHBOARD_PORT}:8000"
    depends_on:
      - database

  orchestrator:
    build:
      context: .
      dockerfile: orchestrator/Dockerfile
    container_name: orchestrator_container
    env_file: .env
    depends_on:
      - database
EOF

log "docker-compose.yml created."

# ---------------------------------------------------------
# 7. Create Makefile
# ---------------------------------------------------------
cat > Makefile <<'EOF'
bootstrap:
	./bootstrap.sh

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

reset:
	docker compose down -v
	rm -rf .venv
EOF

log "Makefile created."

# ---------------------------------------------------------
# 8. Create GitHub Actions CI
# ---------------------------------------------------------
cat > .github/workflows/ci.yml <<EOF
name: CI

on:
  push:
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install project dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Build Docker images
        run: docker compose build
EOF

log "GitHub Actions CI created."

# ---------------------------------------------------------
# 9. Create GitLab CI
# ---------------------------------------------------------
cat > .gitlab-ci.yml <<EOF
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker compose build

deploy:
  stage: deploy
  script:
    - docker compose up -d
EOF

log "GitLab CI created."

# ---------------------------------------------------------
# 10. Create the enhanced bootstrap script
# ---------------------------------------------------------
cat > bootstrap.sh <<'EOF'
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
EOF
chmod +x bootstrap.sh

log "bootstrap.sh created."

log "Full stack setup completed successfully."
