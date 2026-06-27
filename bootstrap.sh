#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/lovegold120221-dot/openbuff.git"
INSTALL_DIR="${OPENBUFF_DIR:-$HOME/.openbuff}"
FREEBUFF2API_DIR="$INSTALL_DIR/freebuff2api"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[openbuff]${NC} $1"; }
warn() { echo -e "${YELLOW}[openbuff]${NC} $1"; }
header() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

header "OpenBuff Bootstrap — https://github.com/lovegold120221-dot/openbuff"

log "Installing to $INSTALL_DIR"

# ── Clone repo ──────────────────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
  warn "$INSTALL_DIR already exists, pulling updates..."
  git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || true
else
  git clone "$REPO" "$INSTALL_DIR"
fi

# ── Symlink opencode config ─────────────────────────────────────
OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

if [ -f "$OPENCODE_CONFIG_DIR/opencode.jsonc" ]; then
  warn "Backing up existing opencode.jsonc to opencode.jsonc.bak"
  cp "$OPENCODE_CONFIG_DIR/opencode.jsonc" "$OPENCODE_CONFIG_DIR/opencode.jsonc.bak"
fi
ln -sf "$INSTALL_DIR/opencode.jsonc" "$OPENCODE_CONFIG_DIR/opencode.jsonc"
ln -sf "$INSTALL_DIR/AGENTS.md" "$OPENCODE_CONFIG_DIR/AGENTS.md"

log "opencode config linked"

# ── Install freebuff2api proxy ──────────────────────────────────
header "freebuff2api Proxy"

if [ ! -d "$FREEBUFF2API_DIR" ]; then
  git clone https://github.com/XxxXTeam/freebuff2api.git "$FREEBUFF2API_DIR"
else
  git -C "$FREEBUFF2API_DIR" pull --ff-only 2>/dev/null || true
fi

python3 -m venv "$FREEBUFF2API_DIR/.venv"
"$FREEBUFF2API_DIR/.venv/bin/pip" install -q -e "$FREEBUFF2API_DIR"

# Apply patch for root-level routes
if [ -f "$INSTALL_DIR/app.py.patch" ]; then
  cd "$FREEBUFF2API_DIR"
  git apply "$INSTALL_DIR/app.py.patch" 2>/dev/null || warn "Patch already applied or conflicted — skipping"
  cd "$INSTALL_DIR"
fi

log "freebuff2api installed at $FREEBUFF2API_DIR"

# ── Configure .env ──────────────────────────────────────────────
if [ ! -f "$FREEBUFF2API_DIR/.env" ]; then
  if [ -f "$HOME/.config/manicode/credentials.json" ]; then
    TOKEN=$(python3 -c "
import json; d=json.load(open('$HOME/.config/manicode/credentials.json'))
print(d.get('default',{}).get('authToken',''))
" 2>/dev/null || echo "")
    if [ -n "$TOKEN" ]; then
      cp "$INSTALL_DIR/.env.example" "$FREEBUFF2API_DIR/.env"
      sed -i "s/your-token-here/$TOKEN/" "$FREEBUFF2API_DIR/.env"
      log "Freebuff token auto-detected from credentials.json"
    fi
  fi
fi

if [ ! -f "$FREEBUFF2API_DIR/.env" ]; then
  cp "$INSTALL_DIR/.env.example" "$FREEBUFF2API_DIR/.env"
  warn "Edit $FREEBUFF2API_DIR/.env and set your FREEBUFF_TOKEN"
fi

# ── Install systemd service ─────────────────────────────────────
header "Systemd Service"

SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$SERVICE_DIR"
sed "s|/path/to/freebuff2api|$FREEBUFF2API_DIR|g" \
  "$INSTALL_DIR/freebuff2api.service" > "$SERVICE_DIR/freebuff2api.service"

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now freebuff2api.service 2>/dev/null || \
  warn "Could not start service (try: systemctl --user start freebuff2api)"
loginctl enable-linger "$USER" 2>/dev/null || true

log "systemd service installed"

# ── Verify ──────────────────────────────────────────────────────
header "Verification"

sleep 2
if curl -sf http://127.0.0.1:8000/models > /dev/null 2>&1; then
  MODELS=$(curl -s http://127.0.0.1:8000/models | python3 -c "
import sys,json
data = json.load(sys.stdin)
for m in data.get('data',[]):
  print(f'  {m[\"id\"]}')
" 2>/dev/null)
  log "Proxy running at http://127.0.0.1:8000"
  echo "$MODELS"
else
  warn "Proxy not responding — start it manually:"
  echo "  cd $FREEBUFF2API_DIR && .venv/bin/python main.py"
fi

header "Done"
log "Run opencode in any project to get started"
log "Select model: /model freebuff/deepseek/deepseek-v4-flash"
echo -e "Config repo: ${CYAN}$REPO${NC}"
