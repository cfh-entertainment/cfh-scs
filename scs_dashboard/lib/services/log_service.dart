// lib/services/log_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/log_entry.dart';

class LogService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LogService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Logs eines Geräts holen
  Future<List<LogEntry>> fetchLogs(int deviceId) async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.get(
      '/devices/$deviceId/logs',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (resp.data as List)
        .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Log-Eintrag löschen
  Future<void> deleteLog(int deviceId, int logId) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.delete(
      '/devices/$deviceId/logs/$logId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
