# ==============================================================================
# مرحله ۱: بیلد پروژه vpn-ui (محیط Alpine)
# ==============================================================================
FROM golang:1.23-alpine AS builder

# فعال کردن دانلود خودکار Toolchain برای وابستگی‌های با نسخه Go بالاتر
ENV GOTOOLCHAIN=auto
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

# نصب ابزارهای بیلد (Alpine از apk استفاده می‌کند)
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3

WORKDIR /app
COPY . .

# رفع مشکل نسخه Go در go.mod پروژه اصلی
RUN go mod edit -go=1.22 || true

# مرتب‌سازی وابستگی‌ها (با GOTOOLCHAIN=auto مشکلی پیش نمی‌آید)
RUN go mod tidy

# بیلد باینری vpn-ui
# ابتدا چک می‌کنیم آیا اسکریپت build.sh وجود دارد، اگر نه مستقیم main.go را بیلد می‌کنیم
RUN if [ -f build.sh ]; then \
        chmod +x build.sh && ./build.sh; \
    else \
        go build -tags "nodaemon" -o vpn-ui main.go; \
    fi

# ==============================================================================
# مرحله ۲: محیط اجرایی (Ubuntu)
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب ابزارهای مورد نیاز (Ubuntu از apt-get استفاده می‌کند)
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

# کپی باینری vpn-ui از مرحله builder (هر دو مسیر احتمالی را چک می‌کنیم)
COPY --from=builder /app/vpn-ui /app/vpn-ui
RUN if [ ! -f /app/vpn-ui ] && [ -f /app/bin/vpn-ui ]; then \
        cp /app/bin/vpn-ui /app/vpn-ui; \
    fi
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
