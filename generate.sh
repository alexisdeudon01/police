#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[SETUP] $*"
}

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "[ERROR] Missing required environment variable: $name" >&2
    exit 1
  fi
}

log "Starting full stack setup..."

# ---------------------------------------------------------
# 1. Validate required environment variables
# ---------------------------------------------------------
require_env ANTHROPIC_API_KEY
require_env OPENAI_API_KEY
require_env SGAI_API_KEY
require_env GH_TOKEN
require_env POSTGRES_USER
require_env POSTGRES_PASSWORD
require_env POSTGRES_DB
require_env DATABASE_URL

DASHBOARD_PORT="${DASHBOARD_PORT:-8080}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# ---------------------------------------------------------
# 2. Create directory structure
# ---------------------------------------------------------
log "Creating service directories..."

mkdir -p database
mkdir -p dashboard
mkdir -p orchestrator

# ---------------------------------------------------------
# 3. Generate Dockerfile: DATABASE
# ---------------------------------------------------------
cat > database/Dockerfile <<EOF
FROM postgres:16

ENV POSTGRES_USER=${POSTGRES_USER}
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENV POSTGRES_DB=${POSTGRES_DB}

EXPOSE 5432
EOF

log "Database Dockerfile created."

# ---------------------------------------------------------
# 4. Generate Dockerfile: DASHBOARD
# ---------------------------------------------------------
cat > dashboard/requirements.txt <<EOF
fastapi
uvicorn[standard]
psycopg[binary]
EOF

cat > dashboard/main.py <<EOF
import os

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def home():
    return {
        "status": "dashboard running",
        "database_url_present": bool(os.getenv("DATABASE_URL")),
        "postgres_user_present": bool(os.getenv("POSTGRES_USER")),
        "postgres_db": os.getenv("POSTGRES_DB"),
        "openai_key_present": bool(os.getenv("OPENAI_API_KEY")),
        "anthropic_key_present": bool(os.getenv("ANTHROPIC_API_KEY")),
        "github_token_present": bool(os.getenv("GH_TOKEN")),
    }
EOF

cat > dashboard/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

log "Dashboard Dockerfile created."

# ---------------------------------------------------------
# 5. Generate orchestrator requirements
# ---------------------------------------------------------
cat > orchestrator/requirements.txt <<EOF
-r ../requirements.txt
EOF

log "Orchestrator requirements created."

# ---------------------------------------------------------
# 6. Generate Dockerfile: ORCHESTRATOR
# ---------------------------------------------------------
cat > orchestrator/Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY orchestrator/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY ai_engine /app/ai_engine
COPY pyproject.toml /app/
COPY setup.cfg /app/

CMD ["python", "-m", "ai_engine.orchestration.executor"]
EOF

log "Orchestrator Dockerfile created."

# ---------------------------------------------------------
# 7. Create docker-compose.yml
# ---------------------------------------------------------
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  database:
    build:
      context: ./database
      dockerfile: Dockerfile
    container_name: db_container
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "${POSTGRES_DB}"
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  dashboard:
    build:
      context: ./dashboard
      dockerfile: Dockerfile
    container_name: dashboard_container
    environment:
      ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY}"
      OPENAI_API_KEY: "${OPENAI_API_KEY}"
      SGAI_API_KEY: "${SGAI_API_KEY}"
      GH_TOKEN: "${GH_TOKEN}"
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "${POSTGRES_DB}"
      DATABASE_URL: "postgresql+psycopg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@database:5432/${POSTGRES_DB}"
    ports:
      - "${DASHBOARD_PORT}:8000"
    depends_on:
      database:
        condition: service_healthy

  orchestrator:
    build:
      context: .
      dockerfile: orchestrator/Dockerfile
    container_name: orchestrator_container
    environment:
      ANTHROPIC_API_KEY: "${ANTHROPIC_API_KEY}"
      OPENAI_API_KEY: "${OPENAI_API_KEY}"
      SGAI_API_KEY: "${SGAI_API_KEY}"
      GH_TOKEN: "${GH_TOKEN}"
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "${POSTGRES_DB}"
      DATABASE_URL: "postgresql+psycopg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@database:5432/${POSTGRES_DB}"
    depends_on:
      database:
        condition: service_healthy

volumes:
  postgres_data:
EOF

log "docker-compose.yml created."

# ---------------------------------------------------------
# 8. Create Makefile
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
# 9. Create bootstrap script
# ---------------------------------------------------------
cat > bootstrap.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[BOOTSTRAP] $*"; }

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "[ERROR] Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_env ANTHROPIC_API_KEY
require_env OPENAI_API_KEY
require_env SGAI_API_KEY
require_env GH_TOKEN
require_env POSTGRES_USER
require_env POSTGRES_PASSWORD
require_env POSTGRES_DB
require_env DATABASE_URL

log "Checking Python..."
command -v python3 >/dev/null || { log "python3 missing"; exit 1; }

VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -e .

log "Checking Docker..."
command -v docker >/dev/null || { log "Docker missing"; exit 1; }

log "Building with docker compose..."
docker compose build

log "Starting services..."
docker compose up -d

log "Bootstrap finished."
EOF
chmod +x bootstrap.sh

log "bootstrap.sh created."
log "Full stack setup completed successfully."
