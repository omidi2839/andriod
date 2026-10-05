# Sales Agent Android 0.1.0
پروژه را با Android Studio باز کنید (پوشه SalesAgentApp)، Gradle Sync را انجام دهید و Run یا Build > Build APK(s) را بزنید.

در اولین اجرا آدرس ریشه Perfex را با https وارد کنید. مثال: https://crm.example.com
قبل از اپ، ماژول `sales_mobile_api_0.1.0.zip` باید در Perfex نصب و فعال باشد.

V1: ورود مستقل، داشبورد، Goals، رتبه/کمیسیون، ویترین، عملکرد، واتساپ تخصیص‌یافته. ثبت سفارش API نیز در سرور آماده است و UI سبد در نسخه بعد از تست اتصال تکمیل می‌شود.

## ساخت APK بدون Android Studio
این نسخه دارای GitHub Actions است. راهنمای `BUILD_APK_WITH_GITHUB_FA.md` را ببینید. Workflow در `.github/workflows/build-apk.yml` قرار دارد و APK تست را به‌صورت Artifact تولید می‌کند.
