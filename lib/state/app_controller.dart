import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_store.dart';

class AppController extends ChangeNotifier {
  final ApiClient api;
  final SessionStore store;
  final LocalAuthentication localAuth;
  bool booting = true, onboarding = true, locked = false, biometric = false;
  bool homeLoading = false, moreLoading = false, libraryLoading = false;
  String? startupError, homeError, libraryError, notice;
  UserProfile? user;
  List<Track> featured = [], tracks = [], favorites = [];
  List<MusicPlaylist> playlists = [];
  Set<String> favoriteIds = {}, favoriteBusy = {};
  int totalTracks = 0,
      _page = 1,
      _homeRequest = 0,
      _libraryRequest = 0,
      _accountGeneration = 0,
      _favoriteRevision = 0;
  bool hasMore = false;
  String? artist;
  Json? security;
  bool _authenticating = false;
  String? securityError;

  AppController({
    ApiClient? client,
    SessionStore? sessionStore,
    LocalAuthentication? auth,
  }) : store = sessionStore ?? const SecureSessionStore(),
       api = client ?? ApiClient(sessionStore ?? const SecureSessionStore()),
       localAuth = auth ?? LocalAuthentication() {
    api.onSessionExpired = () {
      _accountGeneration++;
      user = null;
      locked = false;
      biometric = false;
      favorites = [];
      playlists = [];
      favoriteIds = {};
      _libraryRequest++;
      notice = 'نشستت منقضی شده؛ دوباره وارد حساب شو';
      notifyListeners();
    };
  }
  bool get signedIn => user != null && !locked;
  Future<void> initialize() async {
    booting = true;
    startupError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      onboarding = !(prefs.getBool('onboarding.done') ?? false);
      biometric = await store.biometricEnabled();
      if (!biometric) {
        await api.restore();
        if (api.session?['user'] is Map) {
          user = UserProfile.fromJson(api.session!['user'] as Json);
        } else if (api.session != null) {
          await refreshProfile();
        }
      }
      locked = biometric;
      if (!locked) unawaited(loadHome());
      if (signedIn) unawaited(loadLibrary());
    } catch (_) {
      startupError = 'خواندن اطلاعات امن ممکن نشد؛ دوباره تلاش کن';
    }
    booting = false;
    notifyListeners();
    unawaited(checkSecurity());
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding.done', true);
    onboarding = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.postPublic('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    await acceptLogin(data);
  }

  Future<void> acceptLogin(Json data) async {
    await api.accept(data);
    if (data['user'] is Map) {
      user = UserProfile.fromJson(data['user'] as Json);
    } else {
      await refreshProfile();
    }
    locked = false;
    _accountGeneration++;
    _libraryRequest++;
    favorites = [];
    playlists = [];
    favoriteIds = {};
    favoriteBusy = {};
    notifyListeners();
    unawaited(loadHome());
    unawaited(loadLibrary());
  }

  Future<void> logout() async {
    _accountGeneration++;
    final refresh = api.session?['refresh'];
    try {
      await api.dio.post<void>('/auth/logout', data: {'refresh': refresh});
    } catch (_) {
      /* Always allow local logout, even when the server is unreachable. */
    }
    await api.forget();
    user = null;
    biometric = false;
    locked = false;
    favorites = [];
    favoriteIds = {};
    playlists = [];
    favoriteBusy = {};
    _libraryRequest++;
    notifyListeners();
    unawaited(loadHome());
  }

  Future<bool> authenticate() async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      final available = await localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        throw const ApiFailure(
          'ابتدا اثر انگشت یا چهره را در تنظیمات گوشی ثبت کن',
        );
      }
      return await localAuth.authenticate(
        localizedReason: 'برای ورود امن به Soundify هویتت را تأیید کن',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(
        'تأیید بیومتریک انجام نشد؛ دوباره تلاش کن یا با رمز وارد شو',
      );
    } finally {
      _authenticating = false;
    }
  }

  void lockForBackground() {
    if (!biometric || !signedIn || _authenticating) return;
    locked = true;
    api.suspend();
    _homeRequest++;
    _libraryRequest++;
    notifyListeners();
  }

  Future<void> setBiometric(bool enabled) async {
    if (!signedIn) return;
    if (!await authenticate()) return;
    await store.setBiometric(enabled);
    biometric = enabled;
    notifyListeners();
  }

  Future<void> unlock() async {
    if (!await authenticate()) return;
    final saved = await api.restore();
    if (saved == null) {
      await store.setBiometric(false);
      biometric = false;
      locked = false;
      notifyListeners();
      return;
    }
    if (saved['user'] is Map) {
      user = UserProfile.fromJson(saved['user'] as Json);
    } else {
      await refreshProfile();
    }
    locked = false;
    notifyListeners();
    unawaited(loadHome());
    unawaited(loadLibrary());
  }

  Future<void> passwordInstead() async {
    // Keep biometric preference until password login succeeds; do not expose saved tokens.
    api.suspend();
    user = null;
    locked = false;
    notifyListeners();
    unawaited(loadHome());
  }

  Future<void> refreshProfile() async {
    final generation = _accountGeneration;
    final response = await api.dio.get<Json>('/users/me');
    if (api.session == null || generation != _accountGeneration) return;
    user = UserProfile.fromJson(response.data!);
    await api.accept({...api.session!, 'user': response.data!});
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final generation = _accountGeneration;
    final response = await api.dio.patch<Json>(
      '/users/me',
      data: {'display_name': name},
    );
    if (api.session == null || !signedIn || generation != _accountGeneration) {
      return;
    }
    user = UserProfile.fromJson(response.data!);
    await api.accept({...api.session!, 'user': response.data!});
    notifyListeners();
  }

  Future<void> checkSecurity() async {
    securityError = null;
    try {
      security = await const MethodChannel('ir.soundify/security')
          .invokeMapMethod<String, dynamic>('check');
    } catch (_) {
      securityError = 'بررسی دستگاه در دسترس نیست';
    }
    notifyListeners();
  }

  Future<void> loadHome({String? filter, bool changeFilter = false}) async {
    if (changeFilter) artist = filter;
    final request = ++_homeRequest;
    homeLoading = true;
    homeError = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        api.tracks(featured: true),
        api.tracks(artist: artist),
      ]);
      if (request != _homeRequest) return;
      featured = values[0].items;
      tracks = values[1].items;
      totalTracks = values[1].count;
      hasMore = values[1].hasNext;
      _page = 1;
    } catch (e) {
      if (request == _homeRequest) homeError = errorText(e);
    } finally {
      if (request == _homeRequest) {
        homeLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (moreLoading || !hasMore) return;
    final request = _homeRequest;
    moreLoading = true;
    notifyListeners();
    try {
      final result = await api.tracks(page: _page + 1, artist: artist);
      if (request != _homeRequest) return;
      _page++;
      tracks = [...tracks, ...result.items];
      hasMore = result.hasNext;
    } catch (e) {
      rethrow;
    } finally {
      moreLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLibrary() async {
    if (!signedIn) return;
    final request = ++_libraryRequest;
    final revision = _favoriteRevision;
    libraryLoading = true;
    libraryError = null;
    notifyListeners();
    try {
      final values = await Future.wait<dynamic>([
        api.all('/favorites', Track.fromJson),
        api.all('/playlists', MusicPlaylist.fromJson),
      ]);
      if (request != _libraryRequest || !signedIn) return;
      playlists = values[1] as List<MusicPlaylist>;
      if (revision == _favoriteRevision) {
        final serverTracks = values[0] as List<Track>;
        final pendingTracks = favorites
            .where((t) => favoriteBusy.contains(t.id))
            .toList();
        favorites = serverTracks
            .where((t) => !favoriteBusy.contains(t.id))
            .toList();
        for (final track in pendingTracks) {
          if (favoriteIds.contains(track.id)) favorites.insert(0, track);
        }
        favoriteIds = favorites.map((t) => t.id).toSet();
      }
    } catch (e) {
      if (request == _libraryRequest) libraryError = errorText(e);
    } finally {
      if (request == _libraryRequest) {
        libraryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(Track track) async {
    if (!signedIn) {
      throw const ApiFailure('برای ذخیرهٔ علاقه‌مندی‌ها وارد حساب شو');
    }
    if (favoriteBusy.contains(track.id)) return;
    final generation = _accountGeneration;
    final wasFavorite = favoriteIds.contains(track.id);
    final before = List<Track>.of(favorites);
    _favoriteRevision++;
    favoriteBusy.add(track.id);
    if (wasFavorite) {
      favoriteIds.remove(track.id);
      favorites.removeWhere((t) => t.id == track.id);
    } else {
      favoriteIds.add(track.id);
      favorites.insert(0, track);
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await api.dio.delete<void>('/favorites/${track.id}');
      } else {
        await api.dio.post<void>('/favorites', data: {'track_id': track.id});
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409 && !wasFavorite) {
        return;
      }
      if (signedIn && generation == _accountGeneration) {
        if (wasFavorite) {
          favoriteIds.add(track.id);
        } else {
          favoriteIds.remove(track.id);
        }
        // Roll back only this track; preserve simultaneous changes to other tracks.
        favorites.removeWhere((t) => t.id == track.id);
        if (wasFavorite) {
          favorites.insert(
            before
                .indexWhere((t) => t.id == track.id)
                .clamp(0, favorites.length),
            track,
          );
        }
      }
      rethrow;
    } finally {
      if (generation == _accountGeneration) {
        _favoriteRevision++;
        favoriteBusy.remove(track.id);
      }
      notifyListeners();
    }
  }

  Future<MusicPlaylist> savePlaylist(
    String name,
    String description, {
    int? id,
  }) async {
    final generation = _accountGeneration;
    final data = {'name': name, 'description': description};
    final result = id == null
        ? await api.dio.post<Json>('/playlists', data: data)
        : await api.dio.patch<Json>('/playlists/$id', data: data);
    final playlist = MusicPlaylist.fromJson(result.data!);
    if (generation != _accountGeneration || !signedIn) return playlist;
    if (id == null) {
      playlists.insert(0, playlist);
    } else {
      playlists = playlists.map((p) => p.id == id ? playlist : p).toList();
    }
    notifyListeners();
    return playlist;
  }

  Future<void> deletePlaylist(int id) async {
    final generation = _accountGeneration;
    await api.dio.delete<void>('/playlists/$id');
    if (generation != _accountGeneration || !signedIn) return;
    playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<MusicPlaylist> playlist(int id) async =>
      MusicPlaylist.fromJson((await api.dio.get<Json>('/playlists/$id')).data!);
  Future<void> addTrack(int playlistId, Track track) async {
    final generation = _accountGeneration;
    await api.dio.post<void>(
      '/playlists/$playlistId/tracks',
      data: {'track_id': track.id},
    );
    if (generation == _accountGeneration) await loadLibrary();
  }

  Future<void> removeTrack(int playlistId, String trackId) async {
    final generation = _accountGeneration;
    await api.dio.delete<void>('/playlists/$playlistId/tracks/$trackId');
    if (generation == _accountGeneration) await loadLibrary();
  }
}
