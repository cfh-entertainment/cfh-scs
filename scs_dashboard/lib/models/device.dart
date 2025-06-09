// lib/models/device.dart

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
