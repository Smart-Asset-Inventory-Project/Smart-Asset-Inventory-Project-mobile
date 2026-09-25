import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';

class ApiService {
  /// Set once in main(): expired-session escape hatch to LoginPage.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static void Function()? onUnauthorized;
  static DateTime? _lastRedirect;
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        // Vercel cold start ~5-10s; 15s keeps UX snappy instead of 30s hangs.
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode) {
            options.extra['t0'] = DateTime.now();
          }
          final token = await storage.read(key: AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (res, handler) {
          if (kDebugMode) {
            final t0 = res.requestOptions.extra['t0'] as DateTime?;
            if (t0 != null) {
              debugPrint(
                  'API ${res.requestOptions.method} ${res.requestOptions.path} '
                  '${res.statusCode} in ${DateTime.now().difference(t0).inMilliseconds}ms');
            }
          }
          return handler.next(res);
        },
        onError: (e, handler) async {
          if (kDebugMode) {
            final t0 = e.requestOptions.extra['t0'] as DateTime?;
            if (t0 != null) {
              debugPrint(
                  'API ${e.requestOptions.method} ${e.requestOptions.path} '
                  'ERR ${e.response?.statusCode} in ${DateTime.now().difference(t0).inMilliseconds}ms');
            }
          }
          // 401 only: refresh once and retry. 403 (permission/scope)
          // is never retried — surface backend message instead.
          if (e.response?.statusCode == 401 &&
              !(e.requestOptions.extra['retried'] == true) &&
              !e.requestOptions.path.contains('/auth/')) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              e.requestOptions.headers['Authorization'] =
                  'Bearer ${await storage.read(key: AppConstants.tokenKey)}';
              e.requestOptions.extra['retried'] = true;
              try {
                final res = await _dio.fetch(e.requestOptions);
                return handler.resolve(res);
              } catch (_) {}
            }
            // Refresh dead too (or no refresh token): session is over.
            // Wipe locally and send to login instead of dead-end screens.
            // Skipped for dev-mock tokens and throttled to one per 5s.
            final stored = await storage.read(key: AppConstants.tokenKey);
            final now = DateTime.now();
            if (stored != null &&
                stored.isNotEmpty &&
                stored != 'mock-token' &&
                (_lastRedirect == null ||
                    now.difference(_lastRedirect!) >
                        const Duration(seconds: 5))) {
              _lastRedirect = now;
              await storage.delete(key: AppConstants.tokenKey);
              await storage.delete(key: AppConstants.refreshTokenKey);
              await storage.delete(key: AppConstants.userKey);
              AuthService.clearMemoryCache();
              onUnauthorized?.call();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<bool> _refreshing = Future.value(false);
  bool _isRefreshing = false;

  /// POST /auth/refresh -> accessToken جديد. false لو فشل (لازم لوجن).
  Future<bool> _tryRefresh() async {
    if (_isRefreshing) {
      await _refreshing;
      final t = await storage.read(key: AppConstants.tokenKey);
      return t != null && t.isNotEmpty;
    }
    _isRefreshing = true;
    _refreshing = _doRefresh();
    final ok = await _refreshing;
    _isRefreshing = false;
    return ok;
  }

  Future<bool> _doRefresh() async {
    try {
      final refresh =
          await storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null || refresh.isEmpty) return false;
      final plain = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      final res = await plain.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final token = (data['accessToken'] ?? '').toString();
      if (token.isEmpty) return false;
      await storage.write(key: AppConstants.tokenKey, value: token);
      final rt = (data['refreshToken'] ?? '').toString();
      if (rt.isNotEmpty) {
        await storage.write(key: AppConstants.refreshTokenKey, value: rt);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static final ApiService instance = ApiService._internal();

  late final Dio _dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  Future<Response> get(String path,
      {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {Object? data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {Object? data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> put(String path, {Object? data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
