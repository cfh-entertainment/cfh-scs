// lib/services/sensor_data_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/sensor_data.dart';


class SensorData {
  final int id;
  final DateTime timestamp;
  final double value; // hier anpassen auf dein JSON-Feld

  SensorData({
    required this.id,
    required this.timestamp,
    required this.value,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['dataJson']['value'] as num).toDouble(), // passe key an
    );
  }
}

class SensorDataService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SensorDataService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<List<SensorData>> fetchData(int deviceId,
      {DateTime? from, DateTime? to}) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) throw Exception('Kein JWT gefunden');

    final now = to ?? DateTime.now();
    final yesterday = from ?? now.subtract(const Duration(hours: 24));

    final resp = await _dio.get(
      '/devices/$deviceId/data',
      queryParameters: {
        'from': yesterday.toUtc().toIso8601String(),
        'to':   now.toUtc().toIso8601String(),
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final list = resp.data as List<dynamic>;
    return list
        .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
