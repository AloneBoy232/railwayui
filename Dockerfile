FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب وابستگی‌های سیستمی
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# دانلود باینری آماده 3x-ui (حذف کامل نیاز به کامپایل Go و خطاهای ماژول)
RUN curl -L -o /tmp/x-ui.tar.gz https://github.com/mhsanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /app \
    && rm /tmp/x-ui.tar.gz \
    && mv /app/x-ui/x-ui /app/x-ui-bin \
    && rm -rf /app/x-ui \
    && chmod +x /app/x-ui-bin

# دانلود و نصب Xray-core (نسخه باینری رسمی)
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh
RUN mkdir -p /etc/x-ui /var/log/nginx /app/bin

EXPOSE 8080
CMD ["/app/start.sh"]
