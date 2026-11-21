class Validators {
  static String normalizeDigits(String text) {
    const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
    return text.split('').map((c) {
      final i = fa.indexOf(c), j = ar.indexOf(c);
      return i >= 0
          ? '$i'
          : j >= 0
          ? '$j'
          : c;
    }).join();
  }

  static String? email(String? v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '')
      ? null
      : 'یک ایمیل معتبر وارد کن';
  static String? password(String? v) =>
      (v?.length ?? 0) >= 8 ? null : 'رمز عبور باید حداقل ۸ کاراکتر باشد';
  static String? username(String? v) =>
      RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(v?.trim() ?? '')
      ? null
      : '۳ تا ۳۰ حرف انگلیسی، عدد یا زیرخط';
  static String? code(String? v) =>
      RegExp(r'^\d{6}$').hasMatch(normalizeDigits(v?.trim() ?? ''))
      ? null
      : 'کد ۶ رقمی را وارد کن';
}
