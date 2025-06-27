// lib/models/sensor_data.dart

class SensorData {
  final int id;
  final DateTime timestamp;
  final Map<String, dynamic> dataJson;

  SensorData({
    required this.id,
    required this.timestamp,
    required this.dataJson,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // 1) id als int parsen (falls String)
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId.toString()) ?? 0;

    // 2) timestamp als DateTime
    final tsString = json['timestamp'] as String;
    final timestamp = DateTime.parse(tsString);

    // 3) dataJson ist inline ein Map
    final dj = json['dataJson'];
    final dataJson = dj is Map
        ? Map<String, dynamic>.from(dj as Map)
        : <String, dynamic>{};

    return SensorData(
      id: id,
      timestamp: timestamp,
      dataJson: dataJson,
    );
  }
}
