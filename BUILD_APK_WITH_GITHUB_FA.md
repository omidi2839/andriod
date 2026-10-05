# ساخت APK بدون Android Studio

این پروژه برای ساخت خودکار APK با GitHub Actions آماده شده است.

## روش استفاده

1. در GitHub یک Repository جدید بسازید.
2. تمام محتویات همین پوشه `SalesAgentApp` را در ریشه Repository قرار دهید؛ پوشه `.github` نیز باید آپلود شود.
3. وارد تب **Actions** در Repository شوید.
4. Workflow با نام **Build Android APK** را باز کنید.
5. روی **Run workflow** و سپس دکمه سبز **Run workflow** بزنید.
6. پس از پایان Build، همان صفحه Run را باز کنید.
7. پایین صفحه، در بخش **Artifacts**، فایل **Sales-Agent-App-0.1.0-debug-apk** را دانلود کنید.
8. ZIP دانلودشده از GitHub را باز کنید. فایل `app-debug.apk` داخل آن، APK قابل نصب نسخه تست است.

Workflow علاوه بر اجرای دستی، با Push روی شاخه `main` یا `master` نیز Build را اجرا می‌کند.

## نکته امنیتی

این خروجی Debug برای تست داخلی است. برای انتشار عمومی/Play Store باید Release signing جداگانه تنظیم شود. هیچ رمز، Token یا Signing Key در Repository قرار ندهید.
