#!/bin/bash
set -e

RAILWAY_PORT=${PORT:-8080}
PANEL_PORT=2053

echo "🚀 Starting Railway-Optimized 3x-ui..."
echo "📌 Public Port: $RAILWAY_PORT"

# جایگذاری پورت در کانفیگ Nginx
sed -e "s/\${PORT}/${RAILWAY_PORT}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# تنظیم متغیرهای محیطی پنل
export XUI_PORT=$PANEL_PORT
export XUI_DB_PATH=/etc/x-ui/x-ui.db

echo "🖥️ Starting 3x-ui panel on internal port $PANEL_PORT..."
cd /app/x-ui
/app/x-ui/x-ui &

echo "🌐 Starting Nginx on public port $RAILWAY_PORT..."
exec nginx -g "daemon off;"
