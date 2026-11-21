import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/validators.dart';
import 'package:soundify/core/models.dart';

void main() {
  test('Persian and Arabic OTP digits normalize before submission', () {
    expect(Validators.normalizeDigits('۰۱۲٣٤٥'), '012345');
    expect(Validators.code('۱۲۳۴۵۶'), isNull);
    expect(Validators.code('12a456'), isNotNull);
    expect(Validators.code('12345'), isNotNull);
  });
  test('email, username and password enforce the API contract', () {
    expect(Validators.email(' test@example.com '), isNull);
    expect(Validators.email('test@'), isNotNull);
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('Abcdefg1'), isNull);
    expect(Validators.username('ali_123'), isNull);
    expect(Validators.username('ali user'), isNotNull);
  });
  test('duration formats seconds without an off-by-one minute', () {
    expect(clockText(const Duration(seconds: 0)), '0:00');
    expect(clockText(const Duration(seconds: 267)), '4:27');
  });
}
