// lib/services/user_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class UserService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<List<User>> fetchUsers() async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.get(
      '/users',
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
    return (resp.data as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<User> createUser(String username, String password, String role) async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.post(
      '/users',
      data: {
        'username': username,
        'password': password,
        'role':     role
      },
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
    return User.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> updateUser(int id, {String? password, String? role}) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.put(
      '/users/$id',
      data: {
        if (password != null) 'password': password,
        if (role     != null) 'role':     role
      },
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
  }

  Future<void> deleteUser(int id) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.delete(
      '/users/$id',
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
  }
}
