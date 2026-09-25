import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';

/// AST Auth ضد الباك اند الحقيقي:
/// POST /auth/login -> data.accessToken + data.user.
/// التوكن في secure storage ويتبعت Bearer في كل طلب عبر ApiService.
class AuthService {
  AuthService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final FlutterSecureStorage _storage;
  final Dio _dio;

  /// Memory cache: HideForAuditor + pages call currentUser() per button.
  /// Serves fresh (<60s) user without another /auth/me round-trip.
  static UserModel? _memUser;
  static DateTime? _memAt;
  static const _memTtl = Duration(seconds: 60);

  static void _remember(UserModel u) {
    _memUser = u;
    _memAt = DateTime.now();
  }

  static void clearMemoryCache() {
    _memUser = null;
    _memAt = null;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Backend first, always: healthy backend is used for real.
    // Mock only when it is unreachable or crashing (no response / 5xx).
    // Real rejections (401 wrong password, 403, 400) always surface.
    try {
      final res = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final token = (data['accessToken'] ?? '').toString();
      if (token.isEmpty) throw Exception('Missing accessToken');
      final user =
          UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      await _storage.write(key: AppConstants.tokenKey, value: token);
      final refresh = (data['refreshToken'] ?? '').toString();
      if (refresh.isNotEmpty) {
        await _storage.write(key: AppConstants.refreshTokenKey, value: refresh);
      }
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      _remember(user);
      return user;
    } on DioException catch (e) {
      // Mock فقط للباك الميت (بلا رد / 5xx). الرفض الحقيقي
      // (401 بيانات غلط، 403، 400) يظهر كخطأ ولا يدخل mock أبدا.
      final code = e.response?.statusCode;
      if (AppConstants.allowMockFallback && (code == null || code >= 500)) {
        final mock = UserModel.mock(email);
        await _storage.write(key: AppConstants.tokenKey, value: 'mock-token');
        await _storage.write(
            key: AppConstants.userKey, value: jsonEncode(mock.toJson()));
        return mock;
      }
      throw Exception(loginErrorMessage(e));
    }
  }

  /// سبب فشل اللوجن للعرض: رسالة سيرفر أو مشكلة شبكة واضحة.
  static String loginErrorMessage(DioException e) {
    final net = networkMessage(e);
    if (net == 'timeout') return 'timeoutRetry';
    if (net == 'offline') return 'noInternet';
    return _backendMessage(e, 'Login failed');
  }

  Future<void> logout() async {
    clearMemoryCache();
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  /// المستخدم من الذاكرة أولا (طازج <60s)، ثم /auth/me، ثم المخزن محليا.
  Future<UserModel?> currentUser() async {
    if (_memUser != null &&
        _memAt != null &&
        DateTime.now().difference(_memAt!) < _memTtl) {
      return _memUser;
    }
    final token = await getToken();
    if (token == null || token == 'mock-token') {
      return _storedUser();
    }
    try {
      final res = await _dio.get(
        AppConstants.meEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final user =
          UserModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      _remember(user);
      return user;
    } on DioException {
      return _storedUser();
    }
  }

  Future<UserModel?> _storedUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// رسالة الباك اند (zod VALIDATION_ERROR أو message) بدل رسالة عامة.
  static String backendMessage(DioException e, String fallback) =>
      _backendMessage(e, fallback);

  /// Plain-language error for UI cards: raw Dio text (MDN links etc.)
  /// means nothing to users. Covers the known production case: 500 on
  /// work-orders until the backend deployment + migration lands.
  static String friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 500) {
        return 'Server error (500) — the backend crashed on this request. '
            'Needs a backend-team fix (deployment + migration).';
      }
      if (code == 404) {
        return 'Not found (404) — this API may not be deployed yet.';
      }
      if (code == 403) return backendMessage(e, 'Forbidden (403)');
      if (code == 401) return 'Session expired — please log in again';
      final net = networkMessage(e);
      if (net == 'timeout') return 'Server is waking up — try again';
      if (net == 'offline') return 'No internet connection';
      return backendMessage(e, 'Request failed');
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// رسالة مناسبة لمشاكل الشبكة قبل أي رد سيرفر.
  static String? networkMessage(DioException e) {
    if (e.response != null) return null;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'timeout';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'offline';
      default:
        return 'offline';
    }
  }

  static String _backendMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String) {
        return (err['message'] as String).split('\n').first;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    return fallback;
  }
}
