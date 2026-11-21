import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import '../state/player_controller.dart';
import 'auth_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool busy = false;
  Future<void> action(Future<void> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    await runAction(context, fn);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>(), s = app.security;
    return RefreshIndicator(
      color: lime,
      onRefresh: () async {
        await app.checkSecurity();
        if (app.signedIn && context.mounted) {
          await runAction(context, app.refreshProfile);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        children: [
          const Text(
            'پروفایل و امنیت',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: lime,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  app.user?.displayName ?? 'شنوندهٔ مهمان',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  app.user?.email ?? 'برای ساخت کتابخانهٔ شخصی وارد شو',
                  textDirection: app.user == null
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (!app.signedIn)
                  FilledButton(
                    onPressed: () => showAuth(context),
                    child: const Text('ورود / ثبت‌نام'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _editName(context),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('ویرایش نام نمایشی'),
                  ),
              ],
            ),
          ),
          const SectionTitle(
            'تنظیمات امنیتی',
            subtitle: 'کنترل حسابت در دست توست',
          ),
          Material(
            color: panel,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: app.biometric,
                  onChanged: !app.signedIn || busy
                      ? null
                      : (v) => action(() => app.setBiometric(v)),
                  secondary: const Icon(Icons.fingerprint_rounded, color: lime),
                  title: const Text(
                    'ورود بیومتریک',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    app.signedIn
                        ? 'اثر انگشت یا چهره هنگام بازگشت به برنامه'
                        : 'پس از ورود قابل فعال‌سازی است',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                const ListTile(
                  leading: Icon(
                    Icons.enhanced_encryption_outlined,
                    color: lime,
                  ),
                  title: Text(
                    'حافظهٔ امن دستگاه',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'توکن‌های نشست با رمزنگاری نگهداری می‌شوند',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          SectionTitle(
            'وضعیت دستگاه',
            trailing: IconButton(
              tooltip: 'بررسی دوبارهٔ امنیت',
              onPressed: app.checkSecurity,
              icon: const Icon(Icons.refresh_rounded, color: muted),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                if (s != null) ...[
                  _SecurityRow(
                    'نوع دستگاه',
                    s['emulator'] == true ? 'شبیه‌ساز' : 'گوشی واقعی',
                    s['emulator'] != true,
                  ),
                  const Divider(),
                  _SecurityRow(
                    'نشانه‌های روت',
                    s['rooted'] == true ? 'شناسایی شد' : 'شناسایی نشد',
                    s['rooted'] != true,
                  ),
                  const Divider(),
                  Text(
                    '${s['model']} · Android ${s['android']}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'این بررسی بر پایهٔ نشانه‌های شناخته‌شده است و تشخیص قطعی امنیت دستگاه نیست.',
                    style: TextStyle(color: muted, fontSize: 10, height: 1.8),
                  ),
                ] else
                  Text(
                    app.securityError ?? 'در حال بررسی دستگاه…',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (app.signedIn)
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('از حساب خارج می‌شوی؟'),
                          content: const Text(
                            'پخش موسیقی متوقف و اطلاعات نشست از دستگاه پاک می‌شود.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('انصراف'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('خروج'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true && context.mounted) {
                        await action(() async {
                          await context.read<PlayerController>().clear();
                          await app.logout();
                        });
                      }
                    },
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF9E9E),
                size: 19,
              ),
              label: const Text(
                'خروج از حساب',
                style: TextStyle(color: Color(0xFFFF9E9E)),
              ),
            ),
          const SizedBox(height: 28),
          const Center(child: Brand(size: 24)),
          const SizedBox(height: 9),
          const Text(
            'نسخهٔ ۱.۰.۱ · ساخته‌شده با Flutter',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final input = TextEditingController(
      text: context.read<AppController>().user?.displayName,
    );
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('نام نمایشی'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: input,
            maxLength: 60,
            autofocus: true,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'نام را وارد کن' : null,
            decoration: const InputDecoration(labelText: 'نام تو'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, input.text.trim());
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    // Dispose after the closing route animation releases the field.
    Future<void>.delayed(const Duration(milliseconds: 400), input.dispose);
    if (value != null && context.mounted) {
      await action(() => context.read<AppController>().updateName(value));
    }
  }
}

class _SecurityRow extends StatelessWidget {
  final String title, value;
  final bool good;
  const _SecurityRow(this.title, this.value, this.good);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        good ? Icons.check_circle_outline : Icons.info_outline,
        size: 20,
        color: good ? lime : const Color(0xFFFFBD80),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          color: good ? lime : const Color(0xFFFFBD80),
        ),
      ),
    ],
  );
}
