<div dir="rtl" align="right">

# راهنمای ساخت و آزمون

## امضای نسخهٔ انتشار

فایل نصب تحویلی با کلید اختصاصی امضا شده است. تنظیمات ساخت، اطلاعات امضا را از فایل محلی <code dir="ltr">android/key.properties</code> می‌خوانند. نمونهٔ ساختار فایل:

<div dir="ltr" align="left">

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=soundify
storeFile=C:/path/outside/project/soundify-release.jks
```

</div>

کلید امضا خارج از پروژه نگهداری می‌شود. فایل تنظیمات امضا و فایل کلید در مخزن و آرشیو سورس نیستند. برای اجرای توسعه بدون این فایل، تنظیمات ساخت از کلید پیش‌فرض توسعه استفاده می‌کنند.

<div dir="ltr" align="left">

```sh
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

</div>

خروجی ساخت:

<div dir="ltr" align="left">

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

</div>

کوچک‌سازی کد و منابع فعال است. منابع آیکن اعلان و کنترل‌های صوتی با فایل <code dir="ltr">android/app/src/main/res/raw/keep.xml</code> حفظ می‌شوند.

## آزمون دستگاه

حساب ذخیره‌شده با تأیید حسگر واقعی قابل استفاده است:

<div dir="ltr" align="left">

```sh
flutter test integration_test/app_test.dart -d DEVICE_ID --no-uninstall
```

</div>

برای ورود از فرم، یک فایل محلی خارج از مخزن با کلیدهای <code dir="ltr">TEST_EMAIL</code> و <code dir="ltr">TEST_PASSWORD</code> ساخته و مسیر آن را به گزینهٔ <code dir="ltr">--dart-define-from-file</code> بدهید. گزینهٔ زیر عملیات زندهٔ پلی‌لیست و علاقه‌مندی‌ها را نیز فعال می‌کند؛ پلی‌لیست موقت حذف و وضعیت اولیهٔ لایک بازگردانده می‌شود.

<div dir="ltr" align="left">

```sh
flutter test integration_test/app_test.dart -d DEVICE_ID --no-uninstall --dart-define=TEST_MUTATIONS=true
```

</div>

## آزمون مستقل وب‌سرویس

به پایتون ۳ و یک فایل محلی شامل <code dir="ltr">email</code> و <code dir="ltr">password</code> نیاز دارد:

<div dir="ltr" align="left">

```sh
python tools/api_smoke.py --account /path/to/private-account.json
```

</div>

رمز و توکن در خروجی چاپ نمی‌شوند و فایل اطلاعات حساب نباید به مخزن اضافه شود. نتیجهٔ بررسی‌های ثبت‌شده در [گزارش آزمون](TEST_REPORT.fa.md) آمده است.

## آرشیو سورس

<div dir="ltr" align="left">

```sh
python tools/package_source.py
```

</div>

آرشیو در مسیر <code dir="ltr">deliverables/soundify-source.zip</code> ایجاد می‌شود و شامل کد، مستندات و لینک ویدیو است. فایل نصب، ویدیو، خروجی‌های ساخت و اطلاعات محلی در این آرشیو قرار نمی‌گیرند؛ فایل نصب و ویدیو جداگانه در مخزن و بخش انتشار قابل دریافت‌اند.

</div>
