# مرحله ۱: محیط بیلد (Golang + ابزارهای فرانت‌اند)
FROM golang:1.23-alpine AS builder
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3

# فعال کردن قابلیت دانلود خودکار Toolchain برای ماژول‌های سازگار با نسخه‌های جدیدتر Go
ENV GOTOOLCHAIN=auto

WORKDIR /app
COPY . .

# 🛠️ اصلاح نسخه Go در فایل اصلی پروژه (رفع تایپوی 1.26.2)
RUN go mod edit -go=1.22

# 🛠️ جایگزینی وابستگی‌های خراب با نسخه‌های پایدار واقعی:
RUN go mod edit -replace github.com/xtls/xray-core=github.com/xtls/xray-core@v1.8.24
RUN go mod edit -replace github.com/mymmrac/telego=github.com/mymmrac/telego@v1.3.0

# مرتب‌سازی وابستگی‌ها
RUN go mod tidy

# بیلد نهایی باینری
RUN go build -tags "nodaemon" -o vpn-ui main.go

# ==============================================================================
# مرحله ۲: محیط اجرایی بهینه برای Railway
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب وابستگی‌های سیستمی (unzip اضافه شد تا فایل زیپ Xray را باز کند)
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates unzip && rm -rf /var/lib/apt/lists/*

# دانلود، استخراج و نصب Xray-core
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی فایل‌ها از مرحله بیلد
COPY --from=builder /app/vpn-ui /app/vpn-ui
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh

# تنظیمات نهایی و دسترسی‌ها
RUN chmod +x /app/start.sh /app/vpn-ui
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
