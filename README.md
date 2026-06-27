# OpenBuff

OpenCode configuration with Freebuff as a free AI coding provider.

Freebuff (https://freebuff.com) is the free, ad-supported AI coding agent built on Codebuff.
This config wires it into opencode via the [freebuff2api](https://github.com/XxxXTeam/freebuff2api) proxy.

## One-Command Install

```bash
bash <(curl -s https://raw.githubusercontent.com/lovegold120221-dot/openbuff/main/bootstrap.sh)
```

## Quick Start (Manual)

```bash
# 1. Clone and install the proxy
git clone https://github.com/XxxXTeam/freebuff2api.git
cd freebuff2api
python3 -m venv .venv
.venv/bin/pip install -e .
cp .env.example .env
# Edit .env with your Freebuff token from ~/.config/manicode/credentials.json

# 2. Start the proxy
.venv/bin/python main.py

# 3. Run opencode with this config
opencode
```

## Included Files

| File | Purpose |
|---|---|
| `app.py.patch` | Patch for root-level proxy routes |
| `bootstrap.sh` | One-command setup script |
| `opencode.jsonc` | OpenCode config with Freebuff provider + Ctrl+V keybind |
| `AGENTS.md` | Setup instructions loaded by opencode |
| `.env.example` | Template for freebuff2api proxy config |
| `freebuff2api.service` | systemd user service for persistent proxy |

## Proxy Modification

The `freebuff2api` proxy's `app.py` needs an additional route for root-level paths.
Apply the patch in `app.py.patch` or manually add:

```python
@app.get("/models")
@app.get("/v1/models")
@app.post("/chat/completions")
@app.post("/v1/chat/completions")
```

## Models

- `freebuff/deepseek/deepseek-v4-flash` (default)
- `freebuff/deepseek/deepseek-v4-pro`
- `freebuff/moonshotai/kimi-k2.6`
- `freebuff/minimax/minimax-m3`
- `freebuff/mimo/mimo-v2.5`
- `freebuff/mimo/mimo-v2.5-pro`

## Keybindings

- `Ctrl+V` — paste from clipboard (Linux fix)
