import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';

/// AST Auth: login/logout + تخزين التوكن.
/// يعمل مع باك اند حقيقي، ويسقط لـ mock محلي لو السيرفر غير reachable
/// حتى لا يتعطل شغل الفلاتر.
class AuthService {
  AuthService({FlutterSecureStorage? storage, Dio? dio})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 8),
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
      final data = res.data is Map
          ? res.data['data'] ?? res.data
          : <String, dynamic>{};
      final token = (data['token'] ?? data['accessToken']).toString();
      final user = UserModel.fromJson(Map<String, dynamic>.from(data['user'] ?? data));
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      // Fallback محلي للتجربة بدون باك اند (أي خطأ بدون رد سيرفر).
      // احذفه قبل التسليم النهائي أو اتركه خلف kDebugMode فقط.
      // رد حقيقي (401 بيانات غلط) يظهر كخطأ ولا يدخل mock.
      if (AppConstants.allowMockFallback && e.response == null) {
        final mock = UserModel.mock(email);
        await _storage.write(key: AppConstants.tokenKey, value: 'mock-token');
        await _storage.write(
            key: AppConstants.userKey, value: jsonEncode(mock.toJson()));
        return mock;
      }
      final msg = e.response?.data?['message']?.toString() ?? 'Login failed';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<String?> getToken() =>
      _storage.read(key: AppConstants.tokenKey);

  Future<UserModel?> currentUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }
}
