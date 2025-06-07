// lib/services/device_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// Datenmodell für Device
class Device {
  final int id;
  final String deviceId;
  final String type;
  final DateTime lastSeen;

  Device({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }
}

// Service, um Geräte per REST zu laden
class DeviceService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DeviceService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<List<Device>> fetchDevices() async {
    // 1) Token auslesen
    final token = await _storage.read(key: 'jwt');
    if (token == null) throw Exception('Kein JWT gefunden');

    // 2) GET mit Authorization-Header
    final resp = await _dio.get(
      '/devices',
      options: Options(
        headers: { 'Authorization': 'Bearer $token' }
      ),
    );

    final data = resp.data as List<dynamic>;
    return data.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }
}
