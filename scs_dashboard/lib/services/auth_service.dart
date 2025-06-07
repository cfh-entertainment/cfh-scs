// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();

  // ① Konstruktor erhält ab sofort die Server-URL
  AuthService(String baseUrl)
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<bool> login(String username, String password) async {
    try {
      final resp = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = resp.data['token'] as String;
      await _storage.write(key: 'jwt', value: token);
      return true;
    } on DioError catch (e) {
      print('Login-Fehler: ${e.response?.data}');
      return false;
    }
  }

  Future<String?> getToken() => _storage.read(key: 'jwt');
}
