import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AdminService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<Map<String, dynamic>> fetchStatus() async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.get(
      '/admin/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<void> uploadFirmware(String path) async {
    final token = await _storage.read(key: 'jwt');
    final formData = FormData.fromMap({
      'firmware': await MultipartFile.fromFile(path),
    });
    await _dio.post(
      '/admin/firmware',
      data: formData,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      }),
    );
  }
}
