FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app.py.patch /app/
RUN git clone https://github.com/XxxXTeam/freebuff2api.git /app/freebuff2api && \
    cd /app/freebuff2api && \
    git apply /app/app.py.patch 2>/dev/null || true

RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir -e /app/freebuff2api

ENV FREEBUFF_TOKEN=
ENV FREEBUFF_API_KEY=
ENV FREEBUFF_HOST=0.0.0.0
ENV FREEBUFF_PORT=8000
ENV FREEBUFF_LOG_LEVEL=INFO

EXPOSE 8000
CMD ["/app/venv/bin/python", "/app/freebuff2api/main.py"]
