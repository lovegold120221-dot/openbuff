# OpenBuff

Free AI API — OpenAI-compatible endpoint powered by Freebuff.

Run your own free AI API on any VPS. Works with any OpenAI-compatible chatbot, app, or tool.

## Quick Start — Local

```bash
bash <(curl -s https://raw.githubusercontent.com/lovegold120221-dot/openbuff/main/bootstrap.sh)
```

Then use it like OpenAI:

```bash
curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek/deepseek-v4-flash","messages":[{"role":"user","content":"Hello"}],"stream":false}'
```

## Deploy to VPS

### 1. Clone

```bash
git clone https://github.com/lovegold120221-dot/openbuff.git
cd openbuff/deploy
```

### 2. Configure

```bash
cp .env.production .env
# Edit .env — set FREEBUFF_TOKEN and optionally API_KEY, CADDY_DOMAIN
```

### 3. Deploy

```bash
docker compose up -d
```

### 4. Use from any chatbot

Set your OpenAI client to point at your VPS:

| Setting | Value |
|---|---|
| `base_url` | `https://your-domain.com` |
| `api_key` | Your `API_KEY` from `.env` |
| `model` | `deepseek/deepseek-v4-flash` |

**Python:**

```python
from openai import OpenAI
client = OpenAI(base_url="https://your-domain.com", api_key="your-key")
response = client.chat.completions.create(
    model="deepseek/deepseek-v4-flash",
    messages=[{"role": "user", "content": "Hello"}],
)
```

**cURL:**

```bash
curl https://your-domain.com/v1/chat/completions \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek/deepseek-v4-flash","messages":[{"role":"user","content":"Hello"}],"stream":false}'
```

### 5. Available Models

| Model ID | Description |
|---|---|
| `deepseek/deepseek-v4-flash` | Fast, default |
| `deepseek/deepseek-v4-pro` | Smartest |
| `moonshotai/kimi-k2.6` | Large context |
| `minimax/minimax-m3` | Fastest |
| `mimo/mimo-v2.5` | Balanced |
| `mimo/mimo-v2.5-pro` | Smart |

## Files

| File | Purpose |
|---|---|
| `opencode.jsonc` | OpenCode config with Freebuff provider |
| `AGENTS.md` | Setup instructions |
| `bootstrap.sh` | One-command local setup |
| `app.py.patch` | Patch for proxy root-level routes |
| `deploy/docker-compose.yml` | VPS deployment |
| `deploy/Dockerfile` | API container image |
| `deploy/Caddyfile` | HTTPS reverse proxy |
| `deploy/.env.production` | VPS config template |
