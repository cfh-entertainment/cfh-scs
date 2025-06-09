// lib/models/log_entry.dart

class LogEntry {
  final int id;
  final DateTime timestamp;
  final String message;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.message,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id:        json['id']        as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        message:   json['message']   as String,
      );
}
