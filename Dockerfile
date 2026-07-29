# مرحله ۱: محیط بیلد (Golang + ابزارهای فرانت‌اند)
FROM golang:1.23-alpine AS builder
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3

WORKDIR /app
COPY . .

# 🛠️ مرحله ۱: اصلاح نسخه Go در go.mod خود پروژه (رفع تایپوی نویسنده اصلی)
RUN go mod edit -go=1.22

# 🛠️ مرحله ۲: جایگزینی نسخه خراب و غیرممکن xray-core (v1.260327.0) با نسخه پایدار و واقعی v1.8.24
RUN go mod edit -replace github.com/xtls/xray-core=github.com/xtls/xray-core@v1.8.24

# 🛠️ مرحله ۳: مرتب‌سازی وابستگی‌ها بر اساس جایگزینی جدید
RUN go mod tidy

# 🛠️ مرحله ۴: بیلد نهایی باینری
RUN go build -tags "nodaemon" -o vpn-ui main.go

# ==============================================================================
# مرحله ۲: محیط اجرایی سبک و بهینه برای Railway
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب وابستگی‌های ضروری سیستم‌عامل
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates && rm -rf /var/lib/apt/lists/*

# دانلود و نصب آخرین نسخه باینری Xray-core (جدا از کد Go)
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی باینری کامپایل‌شده از مرحله بیلد
COPY --from=builder /app/vpn-ui /app/vpn-ui

# کپی فایل‌های پیکربندی Nginx و استارت‌آپ
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh

# تنظیم مجوزهای اجرا و ساخت پوشه‌های لازم
RUN chmod +x /app/start.sh /app/vpn-ui
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080

# اجرای اسکریپت ورودی (Entrypoint)
CMD ["/app/start.sh"]
