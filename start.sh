#!/bin/bash
set -e
RAILWAY_PORT=${PORT:-8080}

echo "🚀 Starting Railway-Optimized 3x-ui..."

# جایگذاری پورت در کانفیگ Nginx
sed -e "s/\${PORT}/${RAILWAY_PORT}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "🖥️ Starting x-ui panel..."
cd /app
# اجرای x-ui در پس‌زمینه
./x-ui-bin &

echo "🌐 Starting Nginx on port $RAILWAY_PORT..."
exec nginx -g "daemon off;"
