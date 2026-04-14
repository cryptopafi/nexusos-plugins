#!/usr/bin/env bash
# Deploy Arbitrage Pro Dashboard to VPS
# Usage: bash deploy.sh

set -euo pipefail

VPS="pafi@89.116.229.189"
REMOTE_DIR="/opt/arbitrage-dashboard"
SERVICE_NAME="arbitrage-dashboard"
NGINX_CONF="/etc/nginx/sites-available/arbitrage-dashboard"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$(dirname "$LOCAL_DIR")/state"

echo "=== Deploying Arbitrage Pro Dashboard ==="

# 1. Sync files to VPS
echo "[1/5] Syncing files..."
ssh "$VPS" "mkdir -p $REMOTE_DIR/{static,templates/{partials,components},state}"
rsync -avz --delete \
  "$LOCAL_DIR/app.py" \
  "$LOCAL_DIR/requirements.txt" \
  "$VPS:$REMOTE_DIR/"
rsync -avz "$LOCAL_DIR/static/" "$VPS:$REMOTE_DIR/static/"
rsync -avz "$LOCAL_DIR/templates/" "$VPS:$REMOTE_DIR/templates/"

# 2. Sync state files
echo "[2/5] Syncing state files..."
rsync -avz "$STATE_DIR/" "$VPS:$REMOTE_DIR/state/"

# 3. Install dependencies
echo "[3/5] Installing dependencies..."
ssh "$VPS" "cd $REMOTE_DIR && pip3 install -q -r requirements.txt"

# 4. Create/update systemd service
echo "[4/5] Setting up systemd service..."
ssh "$VPS" "cat > /etc/systemd/system/${SERVICE_NAME}.service << 'EOF'
[Unit]
Description=Arbitrage Pro Dashboard
After=network.target

[Service]
Type=simple
User=pafi
WorkingDirectory=$REMOTE_DIR
ExecStart=/usr/bin/python3 -m uvicorn app:app --host 127.0.0.1 --port 8082
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl restart ${SERVICE_NAME}"

# 5. Nginx reverse proxy
echo "[5/5] Configuring nginx..."
ssh "$VPS" "cat > $NGINX_CONF << 'EOF'
server {
    listen 8080;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }

    location /static/ {
        alias $REMOTE_DIR/static/;
        expires 7d;
        add_header Cache-Control public;
    }
}
EOF
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx"

echo ""
echo "=== Dashboard deployed ==="
echo "URL: http://89.116.229.189:8080/"
echo "Health: http://89.116.229.189:8080/health"
echo "API Docs: http://89.116.229.189:8080/api/docs"
