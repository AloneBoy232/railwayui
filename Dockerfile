FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# نصب وابستگی‌ها + dos2unix برای رفع مشکل انکودینگ ویندوزی
RUN apt-get update && apt-get install -y nginx sqlite3 jq curl ca-certificates unzip dos2unix && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# دانلود 3x-ui و استخراج آن (بدون تغییر نام که ساختار پوشه خراب نشود)
RUN curl -L -o /tmp/x-ui.tar.gz https://github.com/mhsanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /app \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /app/x-ui/x-ui

# دانلود Xray-core
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
    && unzip /tmp/xray.zip -d /usr/local/bin/ \
    && rm /tmp/xray.zip \
    && chmod +x /usr/local/bin/xray

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /app/start.sh

# 🔥 پاکسازی کاراکترهای ویندوزی از فایل‌های اسکریپت (حل مشکل No such file)
RUN dos2unix /app/start.sh /etc/nginx/nginx.conf.template

RUN chmod +x /app/start.sh
RUN mkdir -p /etc/x-ui /var/log/nginx

EXPOSE 8080
CMD ["/app/start.sh"]
