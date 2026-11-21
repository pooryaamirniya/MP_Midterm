import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/validators.dart';
import '../state/app_controller.dart';
import 'theme.dart';
import 'player_screen.dart';
import 'widgets.dart';

Future<void> showAuth(BuildContext context) =>
    Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const AuthScreen()));

enum AuthMode { login, register, otp, forgot, verify, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      username = TextEditingController(),
      name = TextEditingController(),
      code = TextEditingController(),
      confirm = TextEditingController();
  AuthMode mode = AuthMode.login;
  bool busy = false, obscure = true, usePasswordAfterVerify = false;
  String? error, info;
  final Map<String, DateTime> resendTimes = {};
  String get cooldownKey =>
      '${[AuthMode.forgot, AuthMode.reset].contains(mode) ? 'reset' : 'otp'}:${email.text.trim().toLowerCase()}';
  DateTime? get resendAt => resendTimes[cooldownKey];
  Timer? timer;
  int get remaining => resendAt == null
      ? 0
      : ((resendAt!.difference(DateTime.now()).inMilliseconds) / 1000)
            .ceil()
            .clamp(0, 3600);
  void cooldown([int seconds = 60]) {
    resendTimes[cooldownKey] = DateTime.now().add(Duration(seconds: seconds));
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {});
      if (resendTimes.values.every((at) => !at.isAfter(DateTime.now()))) {
        t.cancel();
      }
    });
  }

  void change(AuthMode value) {
    if (busy) return;
    setState(() {
      mode = value;
      error = null;
      info = null;
      code.clear();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in [email, password, username, name, code, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      info = null;
    });
    final app = context.read<AppController>();
    try {
      switch (mode) {
        case AuthMode.login:
          await app.login(email.text.trim(), password.text);
          if (mounted) Navigator.pop(context);
        case AuthMode.register:
          await app.api.postPublic('/auth/register', {
            'email': email.text.trim(),
            'username': username.text.trim(),
            'display_name': name.text.trim().isEmpty
                ? username.text.trim()
                : name.text.trim(),
            'password': password.text,
          });
          usePasswordAfterVerify = true;
          cooldown();
          setState(() => mode = AuthMode.verify);
        case AuthMode.otp:
          final result = await app.api.postPublic('/auth/otp/request', {
            'email': email.text.trim(),
          });
          usePasswordAfterVerify = false;
          cooldown((result['resend_after'] as num?)?.toInt() ?? 60);
          setState(() => mode = AuthMode.verify);
        case AuthMode.verify:
          final result = await app.api.postPublic('/auth/otp/verify', {
            'email': email.text.trim(),
            'code': Validators.normalizeDigits(code.text.trim()),
          });
          if (result['access'] != null && result['refresh'] != null) {
            setState(() => mode = AuthMode.login);
            await app.acceptLogin(result);
            if (mounted) Navigator.pop(context);
          } else if (usePasswordAfterVerify && password.text.isNotEmpty) {
            setState(() => mode = AuthMode.login);
            await app.login(email.text.trim(), password.text);
            if (mounted) Navigator.pop(context);
          } else {
            setState(() {
              mode = AuthMode.login;
              info = 'ایمیل تأیید شد. سرور برای صدور توکن به رمز عبور هم نیاز دارد؛ حالا وارد شو.';
            });
          }
        case AuthMode.forgot:
          final result = await app.api.postPublic(
            '/auth/password/reset/request',
            {'email': email.text.trim()},
          );
          password.clear();
          confirm.clear();
          code.clear();
          cooldown((result['resend_after'] as num?)?.toInt() ?? 60);
          setState(() => mode = AuthMode.reset);
        case AuthMode.reset:
          await app.api.postPublic('/auth/password/reset/confirm', {
            'email': email.text.trim(),
            'code': Validators.normalizeDigits(code.text.trim()),
            'new_password': password.text,
          });
          password.clear();
          confirm.clear();
          setState(() {
            mode = AuthMode.login;
            info = 'رمز عبور تغییر کرد؛ با رمز جدید وارد شو.';
          });
      }
    } catch (e) {
      if (!mounted) return;
      if (mode == AuthMode.login &&
          e is DioException &&
          e.response?.data is Map &&
          e.response?.data['error']?['code'] == 'account_not_verified') {
        setState(() {
          mode = AuthMode.otp;
          info = 'حسابت هنوز تأیید نشده؛ کد تأیید ایمیل را درخواست کن.';
        });
      } else {
        setState(() => error = errorText(e));
        if (e is DioException && e.response?.statusCode == 429) {
          cooldown(
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 60,
          );
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (remaining > 0 || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await context.read<AppController>().api.postPublic(
        mode == AuthMode.reset
            ? '/auth/password/reset/request'
            : '/auth/otp/request',
        {'email': email.text.trim()},
      );
      cooldown((result['resend_after'] as num?)?.toInt() ?? 60);
      if (mounted) {
        setState(() => info = 'کد تازه ارسال شد؛ پوشهٔ Spam را هم بررسی کن.');
      }
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
      if (e is DioException && e.response?.statusCode == 429) cooldown(60);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String get title => switch (mode) {
    AuthMode.login => 'دوباره به ریتم برگرد.',
    AuthMode.register => 'ریتم خودت رو پیدا کن.',
    AuthMode.otp => 'ورود با کد ایمیل',
    AuthMode.forgot => 'رمزت رو فراموش کردی؟',
    AuthMode.verify => 'ایمیلت رو تأیید کن.',
    AuthMode.reset => 'یک شروع تازه.',
  };
  String get subtitle => switch (mode) {
    AuthMode.login => 'وارد شو؛ موسیقی‌های موردعلاقه‌ات منتظرند.',
    AuthMode.register => 'حسابت را بساز و کتابخانهٔ شخصی‌ات را داشته باش.',
    AuthMode.otp => 'کد ۶ رقمی به ایمیلت ارسال می‌شود. در نسخهٔ فعلی سرور، پس از تأیید کد، رمز عبور هم لازم است.',
    AuthMode.forgot => 'ایمیل حسابت را وارد کن تا کد بازیابی برایت بفرستیم.',
    AuthMode.verify =>
      'کد ۶ رقمی ارسال‌شده به ${email.text.trim()} را وارد کن. کد ۵ دقیقه اعتبار دارد.',
    AuthMode.reset => 'کد ایمیل و رمز عبور جدیدت را وارد کن.',
  };
  @override
  Widget build(BuildContext context) {
    final codeStage = mode == AuthMode.verify || mode == AuthMode.reset;
    final passwordStage = [
      AuthMode.login,
      AuthMode.register,
      AuthMode.reset,
    ].contains(mode);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
        appBar: AppBar(
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('بعداً'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                child: AutofillGroup(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Brand(size: 42),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: muted,
                            height: 1.9,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if ([
                          AuthMode.login,
                          AuthMode.register,
                          AuthMode.otp,
                        ].contains(mode)) ...[
                          SegmentedButton<AuthMode>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              textStyle: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: AuthMode.login,
                                label: Text('ورود'),
                              ),
                              ButtonSegment(
                                value: AuthMode.register,
                                label: Text('ثبت‌نام'),
                              ),
                              ButtonSegment(
                                value: AuthMode.otp,
                                label: Text('کد ایمیل'),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: busy
                                ? null
                                : (v) => change(v.first),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (!codeStage) ...[
                          TextFormField(
                            key: const ValueKey('email'),
                            controller: email,
                            onChanged: (_) => setState(() {}),
                            enabled: !busy,
                            validator: Validators.email,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'ایمیل',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (mode == AuthMode.register) ...[
                          TextFormField(
                            controller: username,
                            enabled: !busy,
                            validator: Validators.username,
                            textDirection: TextDirection.ltr,
                            autofillHints: const [AutofillHints.newUsername],
                            decoration: const InputDecoration(
                              labelText: 'نام کاربری',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: name,
                            enabled: !busy,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'نام نمایشی (اختیاری)',
                              counterText: '',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (codeStage) ...[
                          TextFormField(
                            key: const ValueKey('otp-code'),
                            controller: code,
                            enabled: !busy,
                            validator: Validators.code,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[0-9۰-۹٠-٩]'),
                              ),
                            ],
                            autofillHints: const [AutofillHints.oneTimeCode],
                            style: const TextStyle(
                              letterSpacing: 12,
                              fontSize: 24,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'کد تأیید',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (passwordStage) ...[
                          TextFormField(
                            key: const ValueKey('password'),
                            controller: password,
                            enabled: !busy,
                            validator: Validators.password,
                            textDirection: TextDirection.ltr,
                            obscureText: obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: [
                              mode == AuthMode.login
                                  ? AutofillHints.password
                                  : AutofillHints.newPassword,
                            ],
                            onFieldSubmitted: (_) {
                              if (mode == AuthMode.login) submit();
                            },
                            decoration: InputDecoration(
                              labelText: mode == AuthMode.reset
                                  ? 'رمز عبور جدید'
                                  : 'رمز عبور',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: obscure
                                    ? 'نمایش رمز'
                                    : 'پنهان کردن رمز',
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (mode == AuthMode.register ||
                            mode == AuthMode.reset) ...[
                          TextFormField(
                            controller: confirm,
                            enabled: !busy,
                            textDirection: TextDirection.ltr,
                            obscureText: obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            validator: (v) => v == password.text
                                ? null
                                : 'رمزهای عبور یکسان نیستند',
                            decoration: const InputDecoration(
                              labelText: 'تکرار رمز عبور',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (error != null || info != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (error != null ? Colors.red : lime)
                                    .withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                error ?? info!,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.8,
                                  color: error != null
                                      ? const Color(0xFFFFB1B1)
                                      : lime,
                                ),
                              ),
                            ),
                          ),
                        BusyButton(
                          busy: busy,
                          label: switch (mode) {
                            AuthMode.login => 'ورود به Soundify',
                            AuthMode.register => 'ساخت حساب و ارسال کد',
                            AuthMode.otp || AuthMode.forgot => 'ارسال کد تأیید',
                            AuthMode.verify => 'تأیید کد',
                            AuthMode.reset => 'ثبت رمز عبور جدید',
                          },
                          onPressed:
                              remaining > 0 &&
                                  [AuthMode.otp, AuthMode.forgot].contains(mode)
                              ? null
                              : submit,
                        ),
                        if (!codeStage &&
                            remaining > 0 &&
                            [AuthMode.otp, AuthMode.forgot].contains(mode))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'درخواست دوباره تا $remaining ثانیه',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (mode == AuthMode.login)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => change(AuthMode.forgot),
                            child: const Text('رمز عبور را فراموش کردم'),
                          ),
                        if (codeStage) ...[
                          TextButton(
                            onPressed: remaining > 0 || busy ? null : resend,
                            child: Text(
                              remaining > 0
                                  ? 'ارسال دوباره تا $remaining ثانیه'
                                  : 'ارسال دوبارهٔ کد',
                            ),
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => change(
                                    mode == AuthMode.reset
                                        ? AuthMode.forgot
                                        : AuthMode.otp,
                                  ),
                            child: const Text('اصلاح ایمیل'),
                          ),
                        ],
                        if (mode == AuthMode.forgot || mode == AuthMode.reset)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => change(AuthMode.login),
                            child: const Text('بازگشت به ورود'),
                          ),
                        const SizedBox(height: 22),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 15, color: muted),
                            SizedBox(width: 6),
                            Text(
                              'اطلاعات نشست در حافظهٔ امن دستگاه ذخیره می‌شود',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
