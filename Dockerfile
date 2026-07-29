# ==============================================================================
# محیط واحد: بیلد و اجرا در یک ایمیج (حذف مشکل کپی نشدن باینری)
# ==============================================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ۱. نصب ابزارهای سیستمی مورد نیاز
RUN apt-get update && apt-get install -y \
    nginx sqlite3 jq curl ca-certificates unzip dos2unix \
    python3 python3-pip git wget build-essential \
    && rm -rf /var/lib/apt/lists/*

# ۲. نصب Go 1.23 (آخرین نسخه پایدار برای بیلد پروژه)
RUN wget -q https://go.dev/dl/go1.23.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz \
    && rm go1.23.5.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
ENV GOTOOLCHAIN=auto
ENV CGO_ENABLED=1

# ۳. نصب Node.js (در صورت نیاز پروژه برای بیلد فرانت‌اند)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# ۴. دانلود و نصب Xray-core (باینری رسمی)
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

# ۵. کپی کدهای پروژه و بیلد مستقیم در همان محیط نهایی
WORKDIR /app
COPY . /app

# ۶. اصلاح go.mod و بیلد باینری دقیقاً در مسیر نهایی
RUN go mod edit -go=1.22 || true \
    && go mod tidy \
    && (go build -tags "nodaemon" -o /app/vpn-ui . || \
        go build -tags "nodaemon" -o /app/vpn-ui main.go || \
        go build -tags "nodaemon" -o /app/vpn-ui ./cmd/vpn-ui)

# ۷. چک امنیتی: اگر باینری ساخته نشد، با خطای واضح متوقف شو
RUN if [ ! -f /app/vpn-ui ]; then \
        echo "❌ ERROR: vpn-ui binary was not built!" && \
        ls -la /app/ && \
        exit 1; \
    fi \
    && chmod +x /app/vpn-ui

# ۸. کپی فایل‌های پیکربندی
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh
COPY auto_config_api.py /app/auto_config_api.py

# ۹. رفع مشکل انکودینگ ویندوزی
RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template /app/auto_config_api.py 2>/dev/null || true
RUN chmod +x /app/start.sh /app/auto_config_api.py
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
