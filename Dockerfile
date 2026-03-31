FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install minimal system deps (keep image lean)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency manifests first for better layer caching
COPY pyproject.toml setup.cfg requirements.txt /app/
COPY ai_engine /app/ai_engine

# Upgrade packaging tools and install package + pinned requirements
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -e .

# Default command keeps container alive for package usage/testing
CMD ["python", "-c", "import ai_engine; print('ai_engine container is ready')"]
