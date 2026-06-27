FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG FREEBUFF_TOKEN
ENV FREEBUFF_TOKEN=${FREEBUFF_TOKEN}

WORKDIR /app

COPY . .

RUN git clone https://github.com/XxxXTeam/freebuff2api.git /app/freebuff2api && \
    cd /app/freebuff2api && \
    git apply /app/app.py.patch 2>/dev/null || true

RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir -e /app/freebuff2api

COPY .env.example /app/freebuff2api/.env
RUN if [ -n "$FREEBUFF_TOKEN" ]; then \
      sed -i "s/your-token-here/$FREEBUFF_TOKEN/" /app/freebuff2api/.env; \
    fi

EXPOSE 8000

CMD ["/app/venv/bin/python", "/app/freebuff2api/main.py"]
