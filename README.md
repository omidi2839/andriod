# Almas Shop 1.0.1 — GitHub Actions

نسخه ۱.۰.۱ فقط زیرساخت ساخت خودکار را به سورس ۱.۰.۰ اضافه می‌کند؛ عملکرد فروش و API تغییر نکرده است.

## ساخت اولین APK (بدون نصب Flutter)
1. یک مخزن خصوصی مستقل با نام `almas-shop-app` بسازید؛ پروژه کارشناسان یا مخزن ماژول‌های Perfex را جایگزین نکنید.
2. ZIP را استخراج کنید. تمام محتویات پوشه استخراج‌شده (از جمله `.github` و `.gitignore`) را در **ریشه مخزن** قرار دهید. ترجیحاً با Git از پوشه پروژه:
   ```bash
   git init -b main
   git add .
   git commit -m "Almas Shop 1.0.1 CI"
   git remote add origin https://github.com/YOUR_ACCOUNT/almas-shop-app.git
   git push -u origin main
   ```
   اگر از مرورگر استفاده می‌کنید، مطمئن شوید فایل `.github/workflows/build.yml` واقعاً در ریشه مخزن ثبت شده است. ZIP را به‌تنهایی آپلود نکنید. برای فایل workflow ممکن است مجوز workflow در حساب GitHub لازم باشد.
3. در مخزن `Actions → Build Almas Shop → Run workflow` را بزنید. شاخه main و `android` را انتخاب کنید. `api_base` را فقط اگر آدرس HTTPS عملیاتی متفاوت است وارد کنید. پیش‌فرض `https://sejadalmas.iq/` است؛ دسترسی زنده آن هنوز تأیید نشده است.
4. پس از موفقیت اجرا، پایین صفحه Artifacts، فایل `AlmasShop-Android-APK` را دریافت و استخراج کنید. `AlmasShop-1.0.1-android-test.apk` برای نصب آزمایشی است. ممکن است نیاز به مجوز نصب از همان برنامه دانلودکننده باشد. کلید debug در runner موقت است؛ برای به‌روزرسانی APK آزمایشی قبلی ممکن است حذف نسخه آزمایشی قدیمی لازم شود (داده محلی آن از بین می‌رود).
5. گزینه `both` هر دو پلتفرم را می‌سازد؛ `ios` فقط آیفون. `AlmasShop-iOS-Unsigned-NOT-INSTALLABLE` برای بررسی ساخت روی macOS است و روی آیفون نصب نمی‌شود.

## تنظیمات اختیاری انتشار رسمی
در `Settings → Secrets and variables → Actions` مقادیر زیر را تنظیم کنید. رمزها، فایل‌های کلید و پروفایل را در Git commit نکنید. Base64 رمزگذاری امنیتی نیست؛ فایل base64 باید فقط در Secrets باشد.

### Android
Variables: `ANDROID_RELEASE_SIGNING=true`.
Secrets: `ANDROID_KEYSTORE_BASE64` (محتوای base64 فایل keystore یک‌خطی)، `ANDROID_STORE_PASSWORD`، `ANDROID_KEY_ALIAS`، `ANDROID_KEY_PASSWORD`.
خروجی: `AlmasShop-Android-Release` شامل APK و AAB امضاشده. کلید تولید را امن و ثابت نگه دارید. برای انتشار Google Play باید شناسه بسته و الزامات Play را نهایی کنید. نسخه تست برای انتشار مناسب نیست.

### iOS
Variables: `IOS_RELEASE_SIGNING=true`، `IOS_TEAM_ID`، `IOS_EXPORT_METHOD` (پیش‌فرض `app-store-connect`؛ برای تست روی دستگاه‌های ثبت‌شده با پروفایل مناسب `release-testing`).
Secrets: `IOS_CERTIFICATE_BASE64` (فایل P12 شامل کلید خصوصی)، `IOS_CERTIFICATE_PASSWORD`، `IOS_PROFILE_BASE64` (پروفایل provisioning مطابق تیم و Bundle ID دقیق Runner).
Bundle ID مورد انتظار پیش‌فرض Flutter: `iq.sejadalmas.almasShop`؛ قبل از ساخت پروفایل آن را از فایل تولیدشده `ios/Runner.xcodeproj/project.pbxproj` تأیید کنید. Android ID پیش‌فرض: `iq.sejadalmas.almas_shop`. خروجی در صورت موفقیت `AlmasShop-iOS-Signed-IPA` است. برای App Store/TestFlight هنوز ارسال به App Store Connect و بررسی اپ لازم است؛ IPA امضاشده App Store به‌صورت مستقیم روی گوشی نصب نمی‌شود. ثبت دستگاه برای روش Ad Hoc ضروری است. اسکریپت امضا در این محیط Xcode آزمایش نشده است.

### تنظیمات عمومی
- `ALMAS_API_BASE`: متغیر اختیاری برای مسیر پایه HTTPS. هیچ توکن یا رمز مشتری را در URL یا سورس قرار ندهید.
- `FLUTTER_VERSION`: نسخه دقیق Flutter برای ساخت قابل تکرار؛ اگر خالی باشد stable فعلی استفاده می‌شود. بعد از اولین ساخت موفق، نسخه ثبت‌شده در log و فایل pubspec.lock را تثبیت کنید. ساخت از tag `v*` نیز شروع می‌شود. Artifacts فقط ۳۰ روز نگهداری می‌شوند، و منتشر کردن در GitHub Releases خودکار نیست.
- ساخت به صورت پیش‌فرض با دسترسی read-only انجام می‌شود. امضا فقط با فعال کردن متغیر مربوط انجام می‌گیرد. زمان/هزینه runner بسته به سهمیه حساب است.

## سرور و آزمون
قبل از تست خرید باید نسخه ویترین 0.8.39 و مرکز عملکرد بازاریابی 0.4.9.91 نصب باشند. HTTPS معتبر، نشست/CSRF بدون خطای 419 و حساب مشتری با رمز معتبر لازم است. راهنمای عملکرد اپ و آزمون‌ها: `README_FA.md`.

اعتبارسنجی این بسته: ساختار ZIP، YAML، syntax اسکریپت‌های Bash و Python بررسی شده‌اند. Flutter/Android SDK و Xcode در محیط تهیه بسته موجود نبوده‌اند؛ بنابراین build و تست واقعی هنوز اجرا نشده و هیچ APK/IPA واقعی در ZIP نیست. اولین اجرای Actions معیار تأیید ساخت است. API زنده نیز تأیید نشده است.
