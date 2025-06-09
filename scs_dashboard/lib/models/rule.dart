// lib/models/rule.dart

class Rule {
  final int id;
  final int deviceId;
  final int pinId;
  final Map<String, dynamic> conditionJson;
  final Map<String, dynamic> actionJson;
  final Map<String, dynamic> scheduleJson;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rule({
    required this.id,
    required this.deviceId,
    required this.pinId,
    required this.conditionJson,
    required this.actionJson,
    required this.scheduleJson,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
        id:             json['id']             as int,
        deviceId:       json['deviceId']       as int,
        pinId:          json['pinId']          as int,
        conditionJson:  Map<String, dynamic>.from(json['conditionJson']),
        actionJson:     Map<String, dynamic>.from(json['actionJson']),
        scheduleJson:   Map<String, dynamic>.from(json['scheduleJson'] ?? {}),
        type:           json['type']           as String,
        createdAt:      DateTime.parse(json['createdAt'] as String),
        updatedAt:      DateTime.parse(
                            (json['updatedAt'] as String?) 
                            ?? (json['createdAt'] as String)
                        ),
      );
}
