# Freebuff → OpenCode Integration

This document describes how Freebuff (free, ad-supported AI) integrates with
OpenCode as a custom provider, covering the architecture, authentication,
proxy layer, configuration, and deployment.

## Architecture

```
┌─────────────┐    OpenAI-compat     ┌─────────────────┐   Freebuff API   ┌──────────────┐
│  opencode    │ ──────────────────▶ │  freebuff2api    │ ──────────────▶ │  codebuff.com │
│  (client)    │ ◀────────────────── │  (proxy)         │ ◀────────────── │  (Freebuff)   │
└─────────────┘    HTTP 127.0.0.1    └─────────────────┘   auth token     └──────────────┘
       │                  :8000
       │
       ▼
┌──────────────────────┐
│  opencode.jsonc       │  ← provider config, model definitions
│  AGENTS.md            │  ← instructions injected into system prompt
└──────────────────────┘
```

Three layers:

1. **opencode** — the AI coding agent. Sends OpenAI-compatible HTTP requests.
2. **freebuff2api** — Python proxy. Translates OpenAI-format requests into
   Freebuff's internal API. Ad providers (gravity, zeroclick) are injected
   into the request to keep the service free.
3. **Freebuff (codebuff.com)** — backend that serves the actual model inference.

## Provider Model

OpenCode supports custom providers defined in `opencode.jsonc` under
`provider`. Each provider has:

| Field | Purpose |
|---|---|
| `name` | Display name in the UI |
| `api` | Base URL for the OpenAI-compatible endpoint |
| `models` | Map of model IDs to capabilities |

See [opencode.jsonc](./opencode.jsonc) for the full model definitions.

### Model Capabilities

Each model entry declares what it supports:

```jsonc
"deepseek/deepseek-v4-flash": {
  "name": "DeepSeek V4 Flash",
  "tool_call": true,     // can call tools/functions
  "reasoning": true,     // supports chain-of-thought
  "temperature": true,   // supports temperature parameter
  "attachment": false,   // does not support file attachments
  "limit": {
    "context": 65536,    // max context window (tokens)
    "output": 8192       // max output tokens
  },
  "status": "active"
}
```

Setting `tool_call: false` or `reasoning: false` tells opencode not to use
those features, preventing silent failures.

## Authentication Flow

```
1. Install:         npm install -g freebuff
2. Authenticate:    freebuff  (interactive login)
3. Token stored:    ~/.config/manicode/credentials.json
   {
     "default": { "authToken": "fb_..." }
   }
4. Proxy reads:     FREEBUFF_TOKEN=fb_...  (from .env)
5. Proxy forwards:  Authorization: Bearer fb_...  to codebuff.com
```

The token never goes to opencode — only the proxy needs it.

## Proxy Layer (freebuff2api)

The [freebuff2api](https://github.com/XxxXTeam/freebuff2api) project is a
Python FastAPI server that:

- Exposes `/v1/chat/completions` (OpenAI-compatible)
- Exposes `/v1/models` for model listing
- Translates OpenAI request/response format to Freebuff's API
- Injects ad payloads (gravity, zeroclick) to keep the service free
- Applies a client-provided `X-Api-Key` header if `FREEBUFF_API_KEY` is set

### Patch Applied

The repo applies [app.py.patch](./app.py.patch), which adds non-prefixed
routes as aliases:

```python
@app.get("/models")           # ← added
@app.get("/v1/models")        # ← original
@app.post("/chat/completions")  # ← added
@app.post("/v1/chat/completions")  # ← original
```

This provides both `/v1/...` and `/...` routes for compatibility.

## Configuration

### opencode.jsonc

The provider configuration [opencode.jsonc](./opencode.jsonc) registers
`freebuff` as a provider:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md"],
  "model": "freebuff/deepseek/deepseek-v4-flash",
  "small_model": "freebuff/mimo/mimo-v2.5",
  "provider": {
    "freebuff": {
      "name": "Freebuff",
      "api": "http://127.0.0.1:8000",
      "models": { ... }
    }
  }
}
```

The `api` URL points at the local freebuff2api proxy. Model selection uses
`provider/model-id` notation (e.g., `freebuff/deepseek/deepseek-v4-flash`).

### AGENTS.md

[AGENTS.md](./AGENTS.md) is loaded as an instruction file. It injects setup
steps and model information directly into opencode's system prompt, so the
agent knows:
- How to guide users through setup
- What models are available
- Common troubleshooting

## Available Models

| Selector | Model | Context | Tool Call | Reasoning |
|---|---|---|---|---|
| `freebuff/deepseek/deepseek-v4-pro` | DeepSeek V4 Pro | 64K | Yes | Yes |
| `freebuff/deepseek/deepseek-v4-flash` | DeepSeek V4 Flash | 64K | Yes | Yes |
| `freebuff/moonshotai/kimi-k2.6` | Kimi K2.6 | 128K | Yes | Yes |
| `freebuff/minimax/minimax-m3` | MiniMax M3 | 32K | Yes | No |
| `freebuff/mimo/mimo-v2.5-pro` | MiMo 2.5 Pro | 64K | Yes | Yes |
| `freebuff/mimo/mimo-v2.5` | MiMo 2.5 | 64K | Yes | Yes |

## Setup (Local)

### One-command install

```bash
bash <(curl -s https://raw.githubusercontent.com/lovegold120221-dot/openbuff/main/bootstrap.sh)
```

This runs [bootstrap.sh](./bootstrap.sh), which:

1. Clones this repo to `~/.openbuff`
2. Symlinks `opencode.jsonc` and `AGENTS.md` into `~/.config/opencode/`
3. Clones and installs freebuff2api in `~/.openbuff/freebuff2api/`
4. Auto-detects Freebuff token from `~/.config/manicode/credentials.json`
5. Applies the route patch
6. Installs a systemd user service for auto-start
7. Verifies the proxy is running

### Manual step-by-step

```bash
# 1. Install freebuff CLI and authenticate
npm install -g freebuff
freebuff

# 2. Clone this repo and link config
git clone https://github.com/lovegold120221-dot/openbuff.git ~/.openbuff
ln -sf ~/.openbuff/opencode.jsonc ~/.config/opencode/opencode.jsonc
ln -sf ~/.openbuff/AGENTS.md ~/.config/opencode/AGENTS.md

# 3. Install freebuff2api
git clone https://github.com/XxxXTeam/freebuff2api.git ~/.openbuff/freebuff2api
cd ~/.openbuff/freebuff2api
python3 -m venv .venv
.venv/bin/pip install -e .
cp ~/.openbuff/.env.example .env
# Edit .env — set FREEBUFF_TOKEN from ~/.config/manicode/credentials.json

# 4. Start proxy
.venv/bin/python main.py
```

### Keybinding

`Ctrl+V` pastes from clipboard (Linux terminal intercept fix). Configured via:

```jsonc
"keybinds": {
  "input_paste": "ctrl+v"
}
```

## Deployment (VPS)

Deploy the proxy to a VPS at `https://your-domain.com` so any OpenAI-compatible
client can use it — not just opencode.

### docker-compose (recommended)

```bash
cd deploy
cp .env.production .env
# Edit .env — set FREEBUFF_TOKEN and optionally API_KEY, CADDY_DOMAIN
docker compose up -d
```

The stack:
- **api** — freebuff2api in a Python container
- **caddy** — HTTPS reverse proxy with auto-TLS

### Usage from any client

```bash
curl https://your-domain.com/v1/chat/completions \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek/deepseek-v4-flash","messages":[{"role":"user","content":"Hello"}],"stream":false}'
```

## Request Flow (Detailed)

```
opencode                          freebuff2api                       codebuff.com
   │                                  │                                  │
   │  POST /v1/chat/completions        │                                  │
   │  { model, messages, tools,        │                                  │
   │    stream: bool }                 │                                  │
   │─────────────────────────────────▶│                                  │
   │                                  │  Translate format                │
   │                                  │  Inject ad payload               │
   │                                  │─────────────────────────────────▶│
   │                                  │                                  │
   │                                  │◀─────────────────────────────────│
   │  Streaming or full response      │  Model response + ad metadata    │
   │◀─────────────────────────────────│                                  │
   │                                  │                                  │
```

For streaming requests, freebuff2api streams SSE chunks from Freebuff and
reformats them as OpenAI-compatible SSE chunks that opencode can consume.

## File Reference

| File | Role |
|---|---|
| `opencode.jsonc` | OpenCode provider config — registers freebuff models |
| `AGENTS.md` | Instruction file — injected into agent system prompt |
| `bootstrap.sh` | One-command local setup script |
| `.env.example` | Local `.env` template |
| `freebuff2api.service` | systemd user unit for auto-start |
| `app.py.patch` | Adds non-prefixed `/models` and `/chat/completions` routes |
| `deploy/docker-compose.yml` | Production deployment stack |
| `deploy/Dockerfile` | Container image for the proxy |
| `deploy/Caddyfile` | HTTPS reverse proxy config |
| `deploy/.env.production` | Production environment template |
