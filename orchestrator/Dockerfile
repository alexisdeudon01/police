FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY ai_engine /app/ai_engine
COPY pyproject.toml /app/
COPY setup.cfg /app/
COPY setup.py /app/

CMD ["python", "-m", "ai_engine.orchestration.executor"]
