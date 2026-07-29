worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    
    server {
        listen ${PORT};
        server_name _;

        # 1. مسیرهای اختصاصی Xray (ترافیک VPN)
        # پورت داخلی Xray را روی 1080 تنظیم می‌کنیم تا با پورت عمومی 8080 تداخل نداشته باشد
        location /vless-ws {
            proxy_pass http://127.0.0.1:1080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /grpc-service {
            grpc_pass grpc://127.0.0.1:1080;
            grpc_set_header Host $host;
            grpc_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # 2. ریدایرکت ریشه دامنه به پنل
        location = / {
            return 302 /managepanel/;
        }

        # 3. هندل کردن پنل مدیریت و تمام API های آن (مثل /login)
        location / {
            # اگر درخواست از /managepanel/ آمد، اسلش اول را حذف کن
            rewrite ^/managepanel/(.*)$ /$1 break;
            
            proxy_pass http://127.0.0.1:2053;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # بازنویسی لینک‌های HTML/JS برای Sub-path
            sub_filter 'href="/' 'href="/managepanel/';
            sub_filter 'src="/' 'src="/managepanel/';
            sub_filter 'action="/' 'action="/managepanel/';
            sub_filter_once off;
            sub_filter_types text/html application/javascript text/css;
        }
    }
}
