#!/bin/bash
set -e
RAILWAY_PORT=${PORT:-8080}
PANEL_PORT=2053
XRAY_PORT=8080

echo "🚀 Starting Railway-Optimized vpn-ui..."
sed -e "s/\$PORT/$RAILWAY_PORT/g" -e "s/\$PANEL_PORT/$PANEL_PORT/g" -e "s/\$XRAY_PORT/$XRAY_PORT/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

if [ ! -f /etc/x-ui/bin/config.json ]; then
    mkdir -p /etc/x-ui/bin
    echo '{"log": {"loglevel": "warning"}, "inbounds": [], "outbounds": [{"protocol": "freedom", "tag": "direct"}]}' > /etc/x-ui/bin/config.json
fi

echo "🔌 Starting Xray-core..."
xray run -config /etc/x-ui/bin/config.json &

echo "🖥️ Starting vpn-ui panel on port $PANEL_PORT..."
export XUI_PORT=$PANEL_PORT
/app/vpn-ui &

echo "🌐 Starting Nginx on port $RAILWAY_PORT..."
exec nginx -g "daemon off;"
