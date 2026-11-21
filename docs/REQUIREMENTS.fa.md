# تطبیق نیازمندی‌ها با پیاده‌سازی

## احراز هویت و امنیت

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| ثبت‌نام و ورود | فرم‌های مجزا، ایمیل، نام کاربری، رمز و تکرار رمز؛ `lib/ui/auth_screen.dart` |
| اعتبارسنجی ایمیل و رمز | `lib/core/validators.dart` و `test/validators_test.dart` |
| درخواست و تأیید OTP | `/auth/otp/request` و `/auth/otp/verify`؛ شمارش معکوس و ارسال مجدد در فرم کد |
| دریافت توکن از OTP | پذیرش پاسخ حاوی توکن پیاده‌سازی شده؛ قرارداد فعلی سرور فقط `verified` می‌دهد و ورود با `/auth/login` تکمیل می‌شود. توضیح در README و OpenAPI ثبت شده است |
| فراموشی رمز دو مرحله‌ای | درخواست کد ایمیل و تأیید کد همراه رمز جدید؛ `AuthMode.forgot` و `AuthMode.reset` |
| نگهداری Access/Refresh Token در حافظهٔ امن | یک رکورد رمزنگاری‌شده در `lib/core/session_store.dart` |
| عدم ذخیرهٔ توکن متنی در SharedPreferences | SharedPreferences فقط کلید `onboarding.done` را نگه می‌دارد |
| تمدید خودکار بدون خروج در خطای شبکه | interceptor، چرخش refresh، single-flight و retry محدود در `lib/core/api_client.dart`؛ تست‌های شبکه و نشست |
| بیومتریک | `local_auth`، فعال‌سازی با تأیید حسگر، قفل حساب در پس‌زمینه و بازیابی نشست پس از تأیید؛ `AppController` و `BiometricScreen` |
| Root و Emulator | کانال Kotlin در `MainActivity.kt` و نمایش نتیجه در `ProfileScreen` |

## شبکه و API

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| Dio، Base URL، timeout و خطا | `lib/core/api_client.dart` |
| کاتالوگ Featured و همهٔ آهنگ‌ها | `loadHome`، صفحه‌بندی `loadMore` و `lib/ui/home_screen.dart` |
| عنوان، خواننده، آلبوم، کاور و مدت | کارت منتخب‌ها و `TrackTile` در `lib/ui/widgets.dart`؛ اطلاعات کامل در پلیر |
| جست‌وجوی زندهٔ اثر/خواننده | پارامتر `q`، debounce ۴۵۰ میلی‌ثانیه، cancellation و رد پاسخ دیررس در `lib/ui/search_screen.dart` |
| مشاهدهٔ پلی‌لیست اختصاصی | دریافت تمام صفحات `/playlists` و نمایش کتابخانه |
| ایجاد، ویرایش نام/توضیحات و حذف پلی‌لیست | `savePlaylist`، `deletePlaylist`، فرم `playlist_actions.dart` و صفحهٔ جزئیات |
| افزودن/حذف آهنگ پلی‌لیست | مسیرهای `/playlists/:id/tracks` و `/playlists/:id/tracks/:trackId` |
| لایک/آن‌لایک و همگام‌سازی | تغییر خوش‌بینانه، ثبت فوری سرور و rollback اختصاصی آهنگ؛ `toggleFavorite` |
| Loading، Empty و Error/Retry | `LoadingView` و `StateView` در خانه، جست‌وجو، کتابخانه و جزئیات پلی‌لیست |

## صوت و پس‌زمینه

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| استریم آدرس سرور و HTTP 206 | `AudioSource.uri(track.streamUrl)`؛ پاسخ Range واقعی در گزارش آزمون |
| Play/Pause/Next/Previous | کنترلر مشترک `lib/state/player_controller.dart` |
| seek و نمایش زمان سپری‌شده/کل | `_SeekBar` و stream زمان در `lib/ui/player_screen.dart` |
| انتقال خودکار به قطعهٔ بعد | صف `setAudioSources` در just_audio |
| مینی‌پلیر پایین صفحات | `MiniPlayer` در پوستهٔ اصلی، فرم احراز هویت، جزئیات پلی‌لیست و صفحهٔ قفل بیومتریک |
| پخش در پس‌زمینه و صفحهٔ خاموش | `just_audio_background`، سرویس foreground، WAKE_LOCK و AudioSession |
| عنوان، خواننده و کاور در اعلان/قفل | `MediaItem` برای هر قطعه و MediaSession اندروید |
| کنترل اعلان | Play/Pause و جابه‌جایی قطعات از سرویس صوتی؛ آیکن‌ها در `res/raw/keep.xml` حفظ می‌شوند |

## رابط کاربری

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| onboarding فقط اولین اجرا | PageView سه‌صفحه‌ای، ذخیرهٔ `onboarding.done` و آزمون `onboarding_test.dart` |
| Splash با لوگو | launch background و سبک Android 12+ همراه Splash Flutter |
| ورود، ثبت‌نام و فراموشی رمز | `lib/ui/auth_screen.dart` |
| خانه با دسته‌بندی و منتخب‌ها | کارت منتخب‌ها و فیلتر خواننده در `HomeScreen` |
| جست‌وجو | `SearchScreen` |
| کتابخانه با تب پلی‌لیست و علاقه‌مندی | `LibraryScreen` |
| پلیر کامل با کاور و اکولایزر | `PlayerScreen` و نمایش متحرک ریتم متناسب با وضعیت پخش |
| پروفایل و تنظیمات امنیتی | `ProfileScreen` |
| فارسی، RTL و Dark Mode | Directionality سراسری، فونت محلی Vazirmatn و `lib/ui/theme.dart` |

## تحویل

| نیازمندی | محل تحویل |
| --- | --- |
| سورس کامل با Git | همین مخزن؛ آرشیو سورس در Release |
| APK release با arm64-v8a | `submission/app-release.apk` و Release نسخهٔ v1.0.1 |
| README، اجرا، پیش‌نیازها و کتابخانه‌ها | `README.md` |
| ویدیوی ۲ تا ۳ دقیقه | `video/`؛ هنوز اضافه نشده است |
| لینک‌ها در فایل Text | `SUBMISSION_LINKS.txt` |
