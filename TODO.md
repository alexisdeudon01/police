# TODO

- [x] Review and track implementation steps
- [x] Create `ARCHITECTURE.md` with architecture diagram and flow
- [x] Create `Dockerfile` for the `ai_engine` package
- [x] Create `start.sh` to:
  - [x] create/use virtual environment `.venv`
  - [x] validate Python/pip availability
  - [x] upgrade pip/setuptools/wheel
  - [x] install dependencies from `pyproject.toml` (via editable install)
  - [x] stop and remove previous container if present
  - [x] build Docker image `ai-engine:latest`
  - [x] run container `ai-engine-container`
- [x] Mark completed tasks in this file
- [x] Make `start.sh` executable
