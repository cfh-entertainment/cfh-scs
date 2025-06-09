import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/sensor_data_service.dart';
import '../widgets/simple_line_chart.dart';

class SensorDetailScreen extends StatefulWidget {
  final String ip;
  final int deviceId;
  final String deviceName;

  const SensorDetailScreen({
    Key? key,
    required this.ip,
    required this.deviceId,
    required this.deviceName,
  }) : super(key: key);

  @override
  _SensorDetailScreenState createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  late SensorDataService _service;
  late IO.Socket _socket;
  List<SensorData> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = SensorDataService(baseUrl);
    _loadData();
    _connectSocket();
  }

  Future<void> _loadData() async {
    final list = await _service.fetchData(widget.deviceId);
    setState(() {
      _data = list;
      _loading = false;
    });
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
    _socket.on('sensorData', (raw) {
      final d = SensorData.fromJson(raw as Map<String, dynamic>);
      setState(() {
        _data.add(d);
        _data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
      appBar: AppBar(title: Text(widget.deviceName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1) Eigenes Chart-Widget zeigen
                  SimpleLineChart(data: _data),
                  const SizedBox(height: 16),
                  // 2) Liste der Messpunkte
                  Expanded(
                    child: ListView.builder(
                      itemCount: _data.length,
                      itemBuilder: (context, i) {
                        final e = _data[i];
                        return ListTile(
                          title: Text(
                            e.timestamp.toLocal().toString(),
                          ),
                          trailing: Text(e.value.toString()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

