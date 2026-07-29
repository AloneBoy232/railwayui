#!/bin/bash
set -e

RAILWAY_PORT=${PORT:-8080}
PANEL_PORT=2053

echo "🚀 Starting Railway-Optimized vpn-ui..."
echo "📌 Public Port: $RAILWAY_PORT"

# جایگذاری پورت در کانفیگ Nginx
sed -e "s/\${PORT}/${RAILWAY_PORT}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# اجرای سرویس API تولید کانفیگ اتوماتیک
echo "🤖 Starting Auto Config API on port 2054..."
python3 /app/auto_config_api.py &

export XUI_PORT=$PANEL_PORT
export XUI_DB_PATH=/etc/x-ui/x-ui.db

echo "🖥️ Starting vpn-ui panel on internal port $PANEL_PORT..."

# 🔥 چک امنیتی: اگر فایل وجود نداشت، محتویات پوشه را چاپ کن تا بفهمیم کجاست
if [ ! -f /app/vpn-ui ]; then
    echo "❌ ERROR: /app/vpn-ui not found! Listing /app/ contents:"
    ls -la /app/
    exit 1
fi

chmod +x /app/vpn-ui
/app/vpn-ui &

echo "🌐 Starting Nginx on public port $RAILWAY_PORT..."
exec nginx -g "daemon off;"
