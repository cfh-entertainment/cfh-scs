// lib/screens/logs/log_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/log_entry.dart';
import '../../services/log_service.dart';

class LogListScreen extends StatefulWidget {
  final String ip;
  final int deviceId;
  const LogListScreen({Key? key, required this.ip, required this.deviceId})
      : super(key: key);

  @override
  _LogListScreenState createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  late LogService _service;
  List<LogEntry> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = LogService(baseUrl);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final list = await _service.fetchLogs(widget.deviceId);
    setState(() {
      _logs = list;
      _loading = false;
    });
  }

  void _onDelete(int logId) async {
    await _service.deleteLog(widget.deviceId, logId);
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs anzeigen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Keine Logs vorhanden'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i];
                    return ListTile(
                      title: Text(log.message),
                      subtitle: Text(log.timestamp.toLocal().toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _onDelete(log.id),
                      ),
                    );
                  },
                ),
    );
  }
}
