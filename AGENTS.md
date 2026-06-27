# OpenBuff — OpenCode with Freebuff

This configuration adds Freebuff as a provider in opencode.
Freebuff is the free, ad-supported AI coding agent (based on Codebuff).

## Prerequisites

- opencode installed
- Node.js 18+
- Python 3.13+

## Setup

### 1. Install Freebuff CLI (for auth token)

```bash
npm install -g freebuff
```

Run `freebuff` once in any project to authenticate.
The auth token is stored at `~/.config/manicode/credentials.json`.

### 2. Install freebuff2api proxy

```bash
git clone https://github.com/XxxXTeam/freebuff2api.git /path/to/freebuff2api
cd /path/to/freebuff2api
python3 -m venv .venv
.venv/bin/pip install -e .
```

### 3. Configure .env

```bash
cp .env.example .env
```

Edit `.env` with your Freebuff token from `~/.config/manicode/credentials.json`:

```
FREEBUFF_TOKEN=your-auth-token
FREEBUFF_HOST=127.0.0.1
FREEBUFF_PORT=8000
```

### 4. Start proxy

```bash
python main.py
```

Or install as systemd user service:

```bash
cp freebuff2api.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now freebuff2api.service
loginctl enable-linger $USER
```

## Usage

1. Start the freebuff2api proxy
2. Run opencode in the project directory
3. Select model with `/model freebuff/deepseek/deepseek-v4-flash`

### Available Models

| Selector | Model |
|---|---|
| `freebuff/deepseek/deepseek-v4-pro` | DeepSeek V4 Pro |
| `freebuff/deepseek/deepseek-v4-flash` | DeepSeek V4 Flash |
| `freebuff/moonshotai/kimi-k2.6` | Kimi K2.6 |
| `freebuff/minimax/minimax-m3` | MiniMax M3 |
| `freebuff/mimo/mimo-v2.5-pro` | MiMo 2.5 Pro |
| `freebuff/mimo/mimo-v2.5` | MiMo 2.5 |

### Keybinding

- `Ctrl+V` pastes from clipboard (Linux fix for terminal intercept)
