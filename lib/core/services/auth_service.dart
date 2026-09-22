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

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
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
      return user;
    } on DioException catch (e) {
      // Fallback mock فقط لو العلم مفتوح (اختبارات) ولا رد من السيرفر.
      // رد حقيقي (401 بيانات غلط) يظهر كخطأ ولا يدخل mock.
      if (AppConstants.allowMockFallback && e.response == null) {
        final mock = UserModel.mock(email);
        await _storage.write(key: AppConstants.tokenKey, value: 'mock-token');
        await _storage.write(
            key: AppConstants.userKey, value: jsonEncode(mock.toJson()));
        return mock;
      }
      throw Exception(_backendMessage(e, 'Login failed'));
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  /// المستخدم من /auth/me أولا (طازج)، ثم المخزن محليا.
  Future<UserModel?> currentUser() async {
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
