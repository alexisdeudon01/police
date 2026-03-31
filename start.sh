#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=".venv"
IMAGE_NAME="ai-engine:latest"
CONTAINER_NAME="ai-engine-container"

echo "==> Starting environment bootstrap"

# 1) Check Python availability
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is not installed or not in PATH."
  exit 1
fi

# 2) Create virtual environment if missing
if [ ! -d "${VENV_DIR}" ]; then
  echo "==> Creating virtual environment at ${VENV_DIR}"
  python3 -m venv "${VENV_DIR}"
else
  echo "==> Virtual environment already exists: ${VENV_DIR}"
fi

# 3) Activate virtual environment
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

echo "==> Python in use: $(python --version)"
echo "==> Pip in use: $(pip --version)"

# 4) Upgrade packaging toolchain
echo "==> Upgrading pip/setuptools/wheel"
pip install --upgrade pip setuptools wheel

# 5) Install project dependencies/package
echo "==> Installing project in editable mode"
pip install -e .

# 6) Docker checks
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed or not in PATH."
  exit 1
fi

# 7) Stop and remove previous container if exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  echo "==> Stopping existing container: ${CONTAINER_NAME}"
  docker stop "${CONTAINER_NAME}" >/dev/null || true

  echo "==> Removing existing container: ${CONTAINER_NAME}"
  docker rm "${CONTAINER_NAME}" >/dev/null || true
else
  echo "==> No previous container named ${CONTAINER_NAME} found"
fi

# 8) Build image
echo "==> Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" .

# 9) Run container
echo "==> Running container: ${CONTAINER_NAME}"
docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}"

echo "==> Completed successfully"
echo "Virtual env: ${VENV_DIR}"
echo "Docker image: ${IMAGE_NAME}"
echo "Container: ${CONTAINER_NAME}"
