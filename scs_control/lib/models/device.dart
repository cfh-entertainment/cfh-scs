class Device {
  final int id;
  final String name;
  String? status;
  final int? areaId;
  final String? areaName;

  Device({
    required this.id,
    required this.name,
    this.status,
    this.areaId,
    this.areaName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      areaId: json['Area']?['id'],
      areaName: json['Area']?['name'],
    );
  }
}
