// lib/services/rule_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/rule.dart';

class RuleService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RuleService(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<List<Rule>> fetchRules() async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.get(
      '/rules',
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
    return (resp.data as List)
        .map((e) => Rule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Rule> createRule({
    required int deviceId,
    required int pinId,
    required Map<String, dynamic> conditionJson,
    required Map<String, dynamic> actionJson,
    Map<String, dynamic>? scheduleJson,
    required String type,
  }) async {
    final token = await _storage.read(key: 'jwt');
    final resp = await _dio.post(
      '/rules',
      data: {
        'deviceId':       deviceId,
        'pinId':          pinId,
        'conditionJson':  conditionJson,
        'actionJson':     actionJson,
        'scheduleJson':   scheduleJson ?? {},
        'type':           type,
      },
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
    return Rule.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> updateRule({
    required int id,
    Map<String, dynamic>? conditionJson,
    Map<String, dynamic>? actionJson,
    Map<String, dynamic>? scheduleJson,
    String? type,
  }) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.put(
      '/rules/$id',
      data: {
        if (conditionJson != null) 'conditionJson': conditionJson,
        if (actionJson    != null) 'actionJson':    actionJson,
        if (scheduleJson  != null) 'scheduleJson':  scheduleJson,
        if (type          != null) 'type':          type,
      },
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
  }

  Future<void> deleteRule(int id) async {
    final token = await _storage.read(key: 'jwt');
    await _dio.delete(
      '/rules/$id',
      options: Options(headers: { 'Authorization': 'Bearer $token' }),
    );
  }
}
