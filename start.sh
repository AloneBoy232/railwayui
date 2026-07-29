#!/bin/bash
set -euo pipefail

RAILWAY_PORT="${PORT:-8080}"
PANEL_PORT=2053
AUTO_CONFIG_PORT=2054

echo "🚀 Starting Railway-Optimized vpn-ui..."
echo "📌 Public Port: ${RAILWAY_PORT}"

# جایگذاری پورت در کانفیگ Nginx
sed -e "s/\${PORT}/${RAILWAY_PORT}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# مسیر دیتابیس برای کانتینر
export VPNUI_DB_FOLDER=/etc/x-ui
export VPNUI_BIN_FOLDER=/app/bin

cleanup() {
    echo "🛑 Shutting down..."
    if [[ -n "${PANEL_PID:-}" ]] && kill -0 "$PANEL_PID" 2>/dev/null; then
        kill -TERM "$PANEL_PID" 2>/dev/null || true
        wait "$PANEL_PID" 2>/dev/null || true
    fi
    if [[ -n "${AUTO_CONFIG_PID:-}" ]] && kill -0 "$AUTO_CONFIG_PID" 2>/dev/null; then
        kill -TERM "$AUTO_CONFIG_PID" 2>/dev/null || true
        wait "$AUTO_CONFIG_PID" 2>/dev/null || true
    fi
    echo "✅ Cleanup complete"
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

# اجرای سرویس API تولید کانفیگ اتوماتیک
echo "🤖 Starting Auto Config API on port ${AUTO_CONFIG_PORT}..."
python3 /app/auto_config_api.py &
AUTO_CONFIG_PID=$!

# چک امنیتی: اگر فایل وجود نداشت، محتویات پوشه را چاپ کن
if [[ ! -f /app/vpn-ui ]]; then
    echo "❌ ERROR: /app/vpn-ui not found! Listing /app/ contents:"
    ls -la /app/
    exit 1
fi

chmod +x /app/vpn-ui

echo "🖥️ Starting vpn-ui panel on internal port ${PANEL_PORT}..."
/app/vpn-ui &
PANEL_PID=$!

# Wait for the panel to be ready (up to 60s)
echo "⏳ Waiting for panel to become ready..."
PANEL_READY=0
for i in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${PANEL_PORT}/healthz" >/dev/null 2>&1; then
        echo "✅ Panel is ready after ${i}s"
        PANEL_READY=1
        break
    fi
    sleep 1
done
if [[ "$PANEL_READY" -eq 0 ]]; then
    echo "⚠️ Panel did not report ready within 60s — continuing; nginx will surface 502s until it comes up."
fi

echo "🌐 Starting Nginx on public port ${RAILWAY_PORT}..."
exec nginx -g "daemon off;"
