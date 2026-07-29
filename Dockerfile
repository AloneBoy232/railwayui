# ==============================================================================
# مرحله ۱: بیلد پروژه vpn-ui (محیط Alpine)
# ==============================================================================
FROM golang:1.23-alpine AS builder

ENV GOTOOLCHAIN=auto
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

# نصب ابزارهای بیلد + file command (که build.sh به آن نیاز دارد)
RUN apk add --no-cache gcc musl-dev git nodejs npm make python3 bash curl file

WORKDIR /app
COPY . .

# رفع مشکل نسخه Go در go.mod پروژه اصلی
RUN go mod edit -go=1.22 || true
RUN go mod tidy

# 🛠️ حذف بخش backend از build.sh (چون به Docker نیاز دارد و در Railway کار نمی‌کند)
# همچنین حذف بخش‌های غیرضروری که فقط برای نصب روی VPS کاربرد دارند
RUN sed -i '/backend\/build.sh/,/VPN daemon bundle/d' build.sh || true
RUN sed -i '/frontend\/build.sh/,$d' build.sh || true

# اجرای بخش core (ساخت Xray و دانلود فایل‌های geo)
RUN bash build/core/build.sh

# بیلد باینری اصلی vpn-ui (بدون نیاز به build.sh)
RUN go build -tags "nodaemon" -o vpn-ui main.go

# ==============================================================================
# مرحله ۲: محیط اجرایی (Ubuntu)
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx sqlite3 jq curl ca-certificates unzip dos2unix \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# دانلود و نصب Xray-core (نسخه باینری)
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی باینری vpn-ui
COPY --from=builder /app/vpn-ui /app/vpn-ui
RUN chmod +x /app/vpn-ui

# کپی فایل‌های geo از مرحله builder
COPY --from=builder /app/corebundle/core/*.dat /app/bin/
RUN mkdir -p /app/bin && mv /app/bin/*.dat /app/bin/ 2>/dev/null || true

# کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

# رفع مشکل انکودینگ ویندوزی
RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template /app/auto_config_api.py 2>/dev/null || true

RUN chmod +x /app/start.sh /app/auto_config_api.py
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
