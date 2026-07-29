# ==============================================================================
# مرحله ۱: بیلد پروژه vpn-ui (محیط Alpine)
# ==============================================================================
FROM golang:1.23-alpine AS builder

ENV GOTOOLCHAIN=auto
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

RUN apk add --no-cache gcc musl-dev git nodejs npm make python3 bash curl file

WORKDIR /app
COPY . .

RUN go mod edit -go=1.22 || true
RUN go mod tidy

# حذف بخش backend که به docker نیاز دارد
RUN sed -i '/backend\/build.sh/,/VPN daemon bundle/d' build.sh || true
RUN sed -i '/frontend\/build.sh/,$d' build.sh || true

# اجرای ساخت core (xray و geo files)
RUN bash build/core/build.sh || true

# بیلد مستقیم (امتحان کردن چند روش مختلف برای پیدا کردن main package)
RUN go build -tags "nodaemon" -o /app/vpn-ui-built . || \
    go build -tags "nodaemon" -o /app/vpn-ui-built main.go || \
    go build -tags "nodaemon" -o /app/vpn-ui-built ./cmd/vpn-ui || true

# 🛠️ جستجوی هوشمند باینری از هر جای ممکن و انتقال به یک پوشه ثابت
RUN mkdir -p /app/final_bin && \
    if [ -f /app/vpn-ui-built ]; then cp /app/vpn-ui-built /app/final_bin/vpn-ui; \
    elif [ -f /app/bin/vpn-ui ]; then cp /app/bin/vpn-ui /app/final_bin/vpn-ui; \
    elif [ -f /app/vpn-ui ]; then cp /app/vpn-ui /app/final_bin/vpn-ui; \
    elif [ -f /app/build/vpn-ui ]; then cp /app/build/vpn-ui /app/final_bin/vpn-ui; \
    else find /app -name "vpn-ui" -type f -exec cp {} /app/final_bin/vpn-ui \; 2>/dev/null; fi && \
    chmod +x /app/final_bin/vpn-ui

# ==============================================================================
# مرحله ۲: محیط اجرایی (Ubuntu)
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx sqlite3 jq curl ca-certificates unzip dos2unix \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

WORKDIR /app

# کپی باینری پیدا شده از مرحله قبل (حالا مطمئن هستیم که در final_bin است)
COPY --from=builder /app/final_bin/vpn-ui /app/vpn-ui
RUN chmod +x /app/vpn-ui

# کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template /app/auto_config_api.py 2>/dev/null || true
RUN chmod +x /app/start.sh /app/auto_config_api.py
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
