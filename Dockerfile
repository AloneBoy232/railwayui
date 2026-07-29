# ==============================================================================
# مرحله ۱: بیلد پروژه vpn-ui (محیط Alpine)
# ==============================================================================
FROM golang:1.23-alpine AS builder

# فعال کردن دانلود خودکار Toolchain برای وابستگی‌های با نسخه Go بالاتر
ENV GOTOOLCHAIN=auto
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

# نصب ابزارهای بیلد + bash برای اجرای اسکریپت + curl برای دانلود فایل‌های geo
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3 bash curl

WORKDIR /app
COPY . .

# رفع مشکل نسخه Go در go.mod پروژه اصلی
RUN go mod edit -go=1.22 || true

# مرتب‌سازی وابستگی‌ها
RUN go mod tidy

# بیلد باینری vpn-ui با استفاده از اسکریپت رسمی پروژه
RUN chmod +x build.sh && bash build.sh

# ==============================================================================
# مرحله ۲: محیط اجرایی (Ubuntu)
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب ابزارهای مورد نیاز
RUN apt-get update && apt-get install -y \
    nginx sqlite3 jq curl ca-certificates unzip dos2unix \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# دانلود و نصب Xray-core
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی باینری vpn-ui از مرحله builder (اسکریپت build.sh خروجی را در /app/bin/ قرار می‌دهد)
COPY --from=builder /app/bin/vpn-ui /app/vpn-ui
RUN chmod +x /app/vpn-ui

# کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

# رفع مشکل انکودینگ ویندوزی (CRLF -> LF)
RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template /app/auto_config_api.py 2>/dev/null || true

# تنظیم دسترسی‌ها و ساخت پوشه‌ها
RUN chmod +x /app/start.sh /app/auto_config_api.py
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
