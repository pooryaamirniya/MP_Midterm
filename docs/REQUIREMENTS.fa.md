<div dir="rtl" align="right">

# تطبیق نیازمندی‌ها با پیاده‌سازی

## احراز هویت و امنیت

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| ثبت‌نام و ورود | فرم‌های مجزا، ایمیل، نام کاربری، رمز و تکرار رمز؛ <code dir="ltr">lib/ui/auth_screen.dart</code> |
| اعتبارسنجی ایمیل و رمز | <code dir="ltr">lib/core/validators.dart</code> و <code dir="ltr">test/validators_test.dart</code> |
| درخواست و تأیید OTP | <code dir="ltr">/auth/otp/request</code> و <code dir="ltr">/auth/otp/verify</code>؛ شمارش معکوس و ارسال مجدد در فرم کد |
| دریافت توکن از OTP | پذیرش پاسخ حاوی توکن پیاده‌سازی شده؛ قرارداد فعلی سرور فقط <code dir="ltr">verified</code> می‌دهد و ورود با <code dir="ltr">/auth/login</code> تکمیل می‌شود. توضیح در README و OpenAPI ثبت شده است |
| فراموشی رمز دو مرحله‌ای | درخواست کد ایمیل و تأیید کد همراه رمز جدید؛ <code dir="ltr">AuthMode.forgot</code> و <code dir="ltr">AuthMode.reset</code> |
| نگهداری Access/Refresh Token در حافظهٔ امن | یک رکورد رمزنگاری‌شده در <code dir="ltr">lib/core/session_store.dart</code> |
| عدم ذخیرهٔ توکن متنی در SharedPreferences | SharedPreferences فقط کلید <code dir="ltr">onboarding.done</code> را نگه می‌دارد |
| تمدید خودکار بدون خروج در خطای شبکه | interceptor، چرخش refresh، single-flight و retry محدود در <code dir="ltr">lib/core/api_client.dart</code>؛ تست‌های شبکه و نشست |
| بیومتریک | <code dir="ltr">local_auth</code>، فعال‌سازی با تأیید حسگر، قفل حساب در پس‌زمینه و بازیابی نشست پس از تأیید؛ <code dir="ltr">AppController</code> و <code dir="ltr">BiometricScreen</code> |
| Root و Emulator | کانال Kotlin در <code dir="ltr">MainActivity.kt</code> و نمایش نتیجه در <code dir="ltr">ProfileScreen</code> |

## شبکه و API

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| Dio، Base URL، timeout و خطا | <code dir="ltr">lib/core/api_client.dart</code> |
| کاتالوگ Featured و همهٔ آهنگ‌ها | <code dir="ltr">loadHome</code>، صفحه‌بندی <code dir="ltr">loadMore</code> و <code dir="ltr">lib/ui/home_screen.dart</code> |
| عنوان، خواننده، آلبوم، کاور و مدت | کارت منتخب‌ها و <code dir="ltr">TrackTile</code> در <code dir="ltr">lib/ui/widgets.dart</code>؛ اطلاعات کامل در پلیر |
| جست‌وجوی زندهٔ اثر/خواننده | پارامتر <code dir="ltr">q</code>، debounce ۴۵۰ میلی‌ثانیه، cancellation و رد پاسخ دیررس در <code dir="ltr">lib/ui/search_screen.dart</code> |
| مشاهدهٔ پلی‌لیست اختصاصی | دریافت تمام صفحات <code dir="ltr">/playlists</code> و نمایش کتابخانه |
| ایجاد، ویرایش نام/توضیحات و حذف پلی‌لیست | <code dir="ltr">savePlaylist</code>، <code dir="ltr">deletePlaylist</code>، فرم <code dir="ltr">playlist_actions.dart</code> و صفحهٔ جزئیات |
| افزودن/حذف آهنگ پلی‌لیست | مسیرهای <code dir="ltr">/playlists/:id/tracks</code> و <code dir="ltr">/playlists/:id/tracks/:trackId</code> |
| لایک/آن‌لایک و همگام‌سازی | تغییر خوش‌بینانه، ثبت فوری سرور و rollback اختصاصی آهنگ؛ <code dir="ltr">toggleFavorite</code> |
| Loading، Empty و Error/Retry | <code dir="ltr">LoadingView</code> و <code dir="ltr">StateView</code> در خانه، جست‌وجو، کتابخانه و جزئیات پلی‌لیست |

## صوت و پس‌زمینه

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| استریم آدرس سرور و HTTP 206 | <code dir="ltr">AudioSource.uri(track.streamUrl)</code>؛ پاسخ Range واقعی در گزارش آزمون |
| Play/Pause/Next/Previous | کنترلر مشترک <code dir="ltr">lib/state/player_controller.dart</code> |
| seek و نمایش زمان سپری‌شده/کل | <code dir="ltr">_SeekBar</code> و stream زمان در <code dir="ltr">lib/ui/player_screen.dart</code> |
| انتقال خودکار به قطعهٔ بعد | صف <code dir="ltr">setAudioSources</code> در just_audio |
| مینی‌پلیر پایین صفحات | <code dir="ltr">MiniPlayer</code> در پوستهٔ اصلی، فرم احراز هویت، جزئیات پلی‌لیست و صفحهٔ قفل بیومتریک |
| پخش در پس‌زمینه و صفحهٔ خاموش | <code dir="ltr">just_audio_background</code>، سرویس foreground، WAKE_LOCK و AudioSession |
| عنوان، خواننده و کاور در اعلان/قفل | <code dir="ltr">MediaItem</code> برای هر قطعه و MediaSession اندروید |
| کنترل اعلان | Play/Pause و جابه‌جایی قطعات از سرویس صوتی؛ آیکن‌ها در <code dir="ltr">res/raw/keep.xml</code> حفظ می‌شوند |

## رابط کاربری

| نیازمندی | پیاده‌سازی و مسیر بررسی |
| --- | --- |
| onboarding فقط اولین اجرا | PageView سه‌صفحه‌ای، ذخیرهٔ <code dir="ltr">onboarding.done</code> و آزمون <code dir="ltr">onboarding_test.dart</code> |
| Splash با لوگو | launch background و سبک Android 12+ همراه Splash Flutter |
| ورود، ثبت‌نام و فراموشی رمز | <code dir="ltr">lib/ui/auth_screen.dart</code> |
| خانه با دسته‌بندی و منتخب‌ها | کارت منتخب‌ها و فیلتر خواننده در <code dir="ltr">HomeScreen</code> |
| جست‌وجو | <code dir="ltr">SearchScreen</code> |
| کتابخانه با تب پلی‌لیست و علاقه‌مندی | <code dir="ltr">LibraryScreen</code> |
| پلیر کامل با کاور و اکولایزر | <code dir="ltr">PlayerScreen</code> و نمایش متحرک ریتم متناسب با وضعیت پخش |
| پروفایل و تنظیمات امنیتی | <code dir="ltr">ProfileScreen</code> |
| فارسی، RTL و Dark Mode | Directionality سراسری، فونت محلی Vazirmatn و <code dir="ltr">lib/ui/theme.dart</code> |

## تحویل

| نیازمندی | محل تحویل |
| --- | --- |
| سورس کامل با Git | همین مخزن؛ آرشیو سورس در Release |
| APK release با arm64-v8a | <code dir="ltr">submission/app-release.apk</code> و Release نسخهٔ v1.0.1 |
| README، اجرا، پیش‌نیازها و کتابخانه‌ها | <code dir="ltr">README.md</code> |
| ویدیوی ۲ تا ۳ دقیقه | [ویدیوی اجرای برنامه](../video/short_video.mp4)، مدت ۲ دقیقه و ۱۸ ثانیه |
| لینک‌ها در فایل Text | <code dir="ltr">SUBMISSION_LINKS.txt</code> |

</div>
