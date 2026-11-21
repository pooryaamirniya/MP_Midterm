import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundify/core/models.dart';
import 'package:soundify/core/session_store.dart';

class MemoryStore implements SessionStore {
  Json? value;
  bool biometric = false;
  Future<void> Function()? beforeWrite;
  @override
  Future<Json?> read() async => value;
  @override
  Future<void> write(Json session) async {
    await beforeWrite?.call();
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<bool> biometricEnabled() async => biometric;
  @override
  Future<void> setBiometric(bool enabled) async {
    biometric = enabled;
  }
}

class FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  FakeAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => await respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(int status, Object data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
