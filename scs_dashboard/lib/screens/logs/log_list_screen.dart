// lib/screens/logs/log_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/log_entry.dart';
import '../../services/log_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = LogService(baseUrl);
    _loadLogs();
    _connectSocket();
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

  void _connectSocket() {
    final uri = 'http://${widget.ip}:3000';
    _socket = IO.io(uri, {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();
    _socket.onConnect((_) {
      _socket.emit('subscribeDevice', widget.deviceId);
    });
    _socket.on('logCreated', (data) {
      final entry = LogEntry.fromJson(data as Map<String, dynamic>);
      setState(() {
        _logs.add(entry);
        _logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
    });
    _socket.on('logDeleted', (data) {
      final map = data as Map<String, dynamic>;
      final rawId = map['id'];
      final id = rawId is int
          ? rawId
          : int.tryParse(rawId.toString()) ?? 0;
      setState(() {
        _logs.removeWhere((e) => e.id == id);
      });
    });
  }

  @override
  void dispose() {
    _socket.emit('unsubscribeDevice', widget.deviceId);
    _socket.disconnect();
    super.dispose();
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
