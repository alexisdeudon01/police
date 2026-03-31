#!/usr/bin/env bash

Enable strict mode:
-e exits on error
-u treats undefined variables as errors
-o pipefail fails if any part of a pipeline fails
set -euo pipefail

Define virtual environment directory, Docker image name, and container name
VENV_DIR=".venv"
IMAGE_NAME="ai-engine:latest"
CONTAINER_NAME="ai-engine-container"

echo "==> Starting environment bootstrap"

Check if python3 is installed and available in PATH
if ! command -v python3 >/dev/null 2>&1; then
echo "ERROR: python3 is not installed or not in PATH."
exit 1
fi

Create a Python virtual environment if it does not already exist
if [ ! -d "${VENV_DIR}" ]; then
echo "==> Creating virtual environment at ${VENV_DIR}"
python3 -m venv "${VENV_DIR}"
else
echo "==> Virtual environment already exists: ${VENV_DIR}"
fi

Activate the virtual environment (shellcheck disabled because path is dynamic)
shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

Display Python and pip versions in the active virtual environment
echo "==> Python in use: $(python --version)"
echo "==> Pip in use: $(pip --version)"

Upgrade core Python packaging tools for stability and performance
echo "==> Upgrading pip/setuptools/wheel"
pip install --upgrade pip setuptools wheel

Install dependencies from requirements.txt and then install this project in editable mode
echo "==> Installing dependencies from requirements.txt"
pip install -r requirements.txt

echo "==> Installing project in editable mode"
pip install -e .

Check that Docker is installed and available in PATH
if ! command -v docker >/dev/null 2>&1; then
echo "ERROR: docker is not installed or not in PATH."
exit 1
fi

Stop and remove any previously existing container with the same name
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
echo "==> Stopping existing container: ${CONTAINER_NAME}"
docker stop "${CONTAINER_NAME}" >/dev/null || true

echo "==> Removing existing container: ${CONTAINER_NAME}"
docker rm "${CONTAINER_NAME}" >/dev/null || true
else
echo "==> No previous container named ${CONTAINER_NAME} found"
fi

Build the Docker image from the Dockerfile in the current directory
echo "==> Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" .

Run the Docker container in detached mode using the newly built image
echo "==> Running container: ${CONTAINER_NAME}"
docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}"

Final success message summarizing environment setup
echo "==> Completed successfully"
echo "Virtual env: ${VENV_DIR}"
echo "Docker image: ${IMAGE_NAME}"
echo "Container: ${CONTAINER_NAME}"