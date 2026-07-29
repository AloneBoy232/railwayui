# 🚀 Railway-Optimized vpn-ui

این پوشش شامل فایل‌های بازنویسی‌شده برای دیپلوی پروژه vpn-ui روی پلتفرم Railway است.

## 📁 محتویات:
- `Dockerfile`: بیلد و اجرای چندمرحله‌ای (Golang + Ubuntu + Xray + Nginx)
- `nginx.conf.template`: قالب پیکربندی Nginx برای مسیریابی هوشمند ترافیک
- `start.sh`: اسکریپت ورودی (Entrypoint) برای راه‌اندازی هماهنگ سرویس‌ها
- `railway_auto_config.go`: نمونه کد بک‌اند برای ساخت خودکار اینباند بهینه
- `RailwayAutoConfig.vue`: نمونه کامپوننت فرانت‌اند برای دکمه ساخت خودکار کانفیگ

## 🛠️ نحوه استفاده:
1. محتویات این پوشش را در ریشه (Root) ریپازیتوری فورک‌شده‌ی `vpn-ui` خود کپی کنید.
2. کدهای Go و Vue را در مکان‌های مناسب معماری پروژه خود ادغام کنید.
3. در داشبورد Railway، یک Volume با مسیر `/etc/x-ui` برای ذخیره‌سازی پایدار (Persistent Storage) اضافه کنید.
4. دیپلوی کنید و از پنل در آدرس `https://your-domain.up.railway.app/managepanel/` لذت ببرید.
https://github.com/AloneBoy232/railway