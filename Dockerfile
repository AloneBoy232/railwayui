# مرحله 1: بیلد پروژه اصلی vpn-ui
FROM golang:1.25-rc AS builder
ENV GOTOOLCHAIN=auto
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3

WORKDIR /app
COPY . .

# رفع مشکل نسخه Go در go.mod
RUN go mod edit -go=1.22 || true
RUN go mod tidy || true

# بیلد پروژه (اگر build.sh وجود داشت از آن استفاده می‌کنیم)
RUN if [ -f build.sh ]; then chmod +x build.sh && ./build.sh; else go build -tags "nodaemon" -o vpn-ui main.go; fi

# مرحله 2: محیط اجرایی
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates unzip dos2unix python3 python3-pip && rm -rf /var/lib/apt/lists/*

# نصب Xray-core
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

# کپی باینری vpn-ui
WORKDIR /app
COPY --from=builder /app/vpn-ui /app/vpn-ui 2>/dev/null || COPY --from=builder /app/bin/vpn-ui /app/vpn-ui
RUN chmod +x /app/vpn-ui

# کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

# رفع انکودینگ ویندوزی
RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template 2>/dev/null || true
RUN chmod +x /app/start.sh
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
