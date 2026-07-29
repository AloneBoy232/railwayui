# مرحله ۱: محیط بیلد (Golang + ابزارهای فرانت‌اند)
FROM golang:1.23-alpine AS builder
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3

WORKDIR /app
COPY . .

# 🛠️ رفع خطای نسخه Go: اصلاح خودکار go.mod به نسخه معتبر 1.22
RUN go mod edit -go=1.22

# بیلد کردن باینری اصلی
# اگر پروژه شما به جای main.go از اسکریپت build.sh استفاده می‌کند، این خط را به RUN ./build.sh تغییر دهید
RUN go build -tags "nodaemon" -o vpn-ui main.go

# مرحله ۲: محیط اجرایی سبک و بهینه برای Railway
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب وابستگی‌های ضروری
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates && rm -rf /var/lib/apt/lists/*

# دانلود و نصب آخرین نسخه Xray-core
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی باینری کامپایل‌شده از مرحله قبل
COPY --from=builder /app/vpn-ui /app/vpn-ui

# کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh /app/vpn-ui
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080

# اجرای اسکریپت استارت
CMD ["/app/start.sh"]
