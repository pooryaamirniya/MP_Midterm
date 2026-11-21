import 'package:dio/dio.dart';

import 'models.dart';
import 'session_store.dart';

class ApiFailure implements Exception {
  final String message, code;
  final int? retryAfter;
  const ApiFailure(this.message, {this.code = '', this.retryAfter});
  @override
  String toString() => message;
}

String errorText(Object e) {
  if (e is ApiFailure) return e.message;
  if (e is DioException) {
    final data = e.response?.data;
    final error = data is Map ? data['error'] : null;
    if (error is Map) {
      return _messages[error['code']] ??
          error['message']?.toString() ??
          'درخواست انجام نشد';
    }
    if (e.type == DioExceptionType.cancel) return 'درخواست لغو شد';
    if (e.response?.statusCode == 429) return 'کمی صبر کن و دوباره تلاش کن';
    if ((e.response?.statusCode ?? 0) >= 500) {
      return 'سرور موقتاً پاسخ نمی‌دهد؛ دوباره تلاش کن';
    }
    return 'اتصال برقرار نشد. اینترنت را بررسی کن و دوباره تلاش کن';
  }
  return 'عملیات انجام نشد؛ دوباره تلاش کن';
}

const _messages = {
  'invalid_credentials': 'ایمیل یا رمز عبور درست نیست',
  'account_not_verified': 'ابتدا ایمیلت را با کد تأیید فعال کن',
  'account_disabled': 'این حساب غیرفعال شده است',
  'email_already_exists': 'این ایمیل قبلاً ثبت شده؛ وارد حساب شو',
  'username_already_exists': 'این نام کاربری قبلاً انتخاب شده است',
  'invalid_email': 'ایمیل معتبر نیست',
  'weak_password': 'رمز عبور قوی‌تری انتخاب کن',
  'invalid_otp': 'کد تأیید درست نیست',
  'otp_expired': 'کد منقضی شده؛ کد تازه درخواست کن',
  'otp_attempts_exceeded': 'تعداد تلاش‌ها تمام شد؛ کد تازه درخواست کن',
  'user_not_found': 'حسابی با این ایمیل پیدا نشد',
  'already_favorited': 'این آهنگ در علاقه‌مندی‌ها هست',
  'already_in_playlist': 'این آهنگ قبلاً به پلی‌لیست اضافه شده است',
  'rate_limited': 'برای درخواست کد تازه، یک دقیقه صبر کن',
};

class ApiClient {
  static const baseUrl = 'https://soundify.easyfound.ir/api/v1';
  final SessionStore store;
  final Dio dio;
  final Dio refreshDio;
  Json? session;
  Future<void>? _refreshing;
  int _refreshGeneration = -1;
  bool _suspended = false;
  Future<void> _storageQueue = Future.value();
  int _generation = 0;
  void Function()? onSessionExpired;

  ApiClient(this.store, {Dio? transport, Dio? refreshTransport})
    : dio = transport ?? Dio(),
      refreshDio = refreshTransport ?? Dio() {
    for (final client in [dio, refreshDio]) {
      client.options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 35),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json', 'User-Agent': 'Soundify/1.0'},
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['public'] != true && session?['access'] != null) {
            options.headers['Authorization'] = 'Bearer ${session!['access']}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              request.extra['public'] == true ||
              request.extra['retried'] == true ||
              session == null) {
            handler.next(error);
            return;
          }
          try {
            // A parallel request may already have rotated the token.
            if (request.headers['Authorization'] ==
                'Bearer ${session!['access']}') {
              await refresh();
            }
            if (session == null) {
              handler.next(error);
              return;
            }
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer ${session!['access']}';
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (e) {
            handler.reject(e);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> accept(Json value) async {
    final generation = ++_generation;
    _suspended = false;
    await _persist(() async {
      if (generation == _generation) await store.write(value);
    });
    if (generation == _generation && !_suspended) {
      session = value;
    }
  }

  /// Lock account access while allowing an already rotating pair to be saved.
  void suspend() {
    _suspended = true;
    session = null;
  }

  Future<Json?> restore() async {
    final generation = _generation;
    final pending = _refreshing;
    if (pending != null && _refreshGeneration == generation) {
      try {
        await pending;
      } on DioException {
        // Read the latest stored pair; transport failures do not erase it.
      }
    }
    await _storageQueue;
    if (generation != _generation) return null;
    final saved = await store.read();
    if (generation != _generation) return null;
    _suspended = false;
    session = saved;
    return saved;
  }

  Future<void> _persist(Future<void> Function() action) {
    final operation = _storageQueue.then((_) => action());
    _storageQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> refresh() {
    if (_refreshing != null && _refreshGeneration == _generation) {
      return _refreshing!;
    }
    late final Future<void> operation;
    _refreshGeneration = _generation;
    operation = _rotate().whenComplete(() {
      if (identical(_refreshing, operation)) _refreshing = null;
    });
    return _refreshing = operation;
  }

  Future<void> _rotate() async {
    final generation = _generation;
    final current = session;
    if (current == null) return;
    try {
      final result = await refreshDio.post<Json>(
        '/auth/token/refresh',
        data: {'refresh': current['refresh']},
      );
      if (generation != _generation) return;
      final next = {...current, ...result.data!};
      await _persist(() async {
        if (generation == _generation) await store.write(next);
      });
      if (generation == _generation && !_suspended) session = next;
    } on DioException catch (e) {
      // A network outage must never destroy an otherwise valid session.
      if (generation == _generation &&
          [400, 401, 403].contains(e.response?.statusCode)) {
        await forget();
        onSessionExpired?.call();
      }
      rethrow;
    }
  }

  Future<void> forget() async {
    _generation++;
    _suspended = false;
    session = null;
    await _persist(() async {
      await store.clear();
      await store.setBiometric(false);
    });
  }

  Future<Json> postPublic(String path, Json data) async =>
      (await dio.post<Json>(
        path,
        data: data,
        options: Options(extra: {'public': true}),
      )).data!;

  Future<PageResult<Track>> tracks({
    int page = 1,
    String query = '',
    String? artist,
    bool featured = false,
    CancelToken? cancelToken,
  }) async {
    final result = await dio.get<Json>(
      featured ? '/tracks/featured' : '/tracks',
      queryParameters: {
        'page': page,
        'page_size': 30,
        if (query.isNotEmpty) 'q': query,
        'artist': ?artist,
      },
      cancelToken: cancelToken,
    );
    return PageResult.fromJson(result.data!, Track.fromJson);
  }

  Future<List<T>> all<T>(String path, T Function(Json) parse) async {
    final output = <T>[];
    for (var page = 1; ; page++) {
      final result = await dio.get<Json>(
        path,
        queryParameters: {'page': page, 'page_size': 50},
      );
      final parsed = PageResult.fromJson(result.data!, parse);
      output.addAll(parsed.items);
      if (!parsed.hasNext) return output;
    }
  }
}
