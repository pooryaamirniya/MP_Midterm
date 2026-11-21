import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

abstract class SessionStore {
  Future<Json?> read();
  Future<void> write(Json session);
  Future<void> clear();
  Future<bool> biometricEnabled();
  Future<void> setBiometric(bool enabled);
}

/// Tokens are one encrypted record, so rotation never persists a mixed pair.
class SecureSessionStore implements SessionStore {
  final FlutterSecureStorage storage;
  const SecureSessionStore([this.storage = const FlutterSecureStorage()]);
  @override
  Future<Json?> read() async {
    final raw = await storage.read(key: 'soundify.session.v1');
    return raw == null ? null : jsonDecode(raw) as Json;
  }

  @override
  Future<void> write(Json session) =>
      storage.write(key: 'soundify.session.v1', value: jsonEncode(session));
  @override
  Future<void> clear() => storage.delete(key: 'soundify.session.v1');
  @override
  Future<bool> biometricEnabled() async =>
      await storage.read(key: 'soundify.biometric') == 'true';
  @override
  Future<void> setBiometric(bool enabled) =>
      storage.write(key: 'soundify.biometric', value: '$enabled');
}
