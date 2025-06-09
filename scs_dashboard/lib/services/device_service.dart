import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/device.dart';

class DeviceService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DeviceService(String baseUrl)
    : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // 1) fetchDevices – liest alle Geräte
  Future<List<Device>> fetchDevices() async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.get(
      '/devices',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = resp.data as List<dynamic>;
    return data
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 2) createDevice – anlegen eines neuen Geräts
  Future<Device> createDevice(String deviceId, String type) async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.post(
      '/devices',
      data: {'deviceId': deviceId, 'type': type},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Device.fromJson(resp.data as Map<String, dynamic>);
  }

  // 3) updateDevice – bearbeiten eines bestehenden Geräts
  Future<void> updateDevice(int id, {
    String? deviceId,
    String? type,
    Map<String, dynamic>? configJson,
  }) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.put(
      '/devices/$id',
      data: {
        if (deviceId != null)  'deviceId':  deviceId,
        if (type       != null)  'type':      type,
        if (configJson != null)  'configJson': configJson,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 4) deleteDevice – löscht ein Gerät
  Future<void> deleteDevice(int id) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.delete(
      '/devices/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
