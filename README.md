# 🚀 Railway-Optimized vpn-ui

این پوشش شامل فایل‌های بازنویسی‌شده برای دیپلوی پروژه vpn-ui روی پلتفرم Railway است.

## 📁 محتویات:
- `Dockerfile`: بیلد و اجرای چندمرحله‌ای (Golang + Ubuntu + Xray + Nginx)
- `nginx.conf.template`: قالب پیکربندی Nginx برای مسیریابی هوشمند ترافیک
- `start.sh`: اسکریپت ورودی (Entrypoint) برای راه‌اندازی هماهنگ سرویس‌ها
- `RailwayAutoConfig.vue`: نمونه کامپوننت Vue برای ساخت خودکار کانفیگ Railway
- `auto_config_api.py`: سرویس پایتون تولید کانفیگ
- `web/railway_api.go`: اندپوینت بکند `/api/railway-auto` در Go
- `web/assets/railway-auto-inject.js`: کد جاوااسکریپتی که دکمه را به UI تزریق می‌کند
- `RailwayAutoConfig.vue`: نمونه کامپوننت فرانت‌اند برای دکمه ساخت خودکار کانفیگ

## 🛠️ نحوه استفاده:
1. محتویات این پوشش را در ریشه (Root) ریپازیتوری فورک‌شده‌ی `vpn-ui` خود کپی کنید.
2. کدهای Go و Vue را در مکان‌های مناسب معماری پروژه خود ادغام کنید.
3. در داشبورد Railway، یک Volume با مسیر `/etc/x-ui` برای ذخیره‌سازی پایدار (Persistent Storage) اضافه کنید.
4. دیپلوی کنید و از پنل در آدرس `https://your-domain.up.railway.app/managepanel/` لذت ببرید.
https://github.com/AloneBoy232/railway