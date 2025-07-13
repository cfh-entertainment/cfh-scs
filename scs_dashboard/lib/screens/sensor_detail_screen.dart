import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// Nur die Service-Klasse importieren, nicht das Modell:
import '../services/sensor_data_service.dart' show SensorDataService;
// Wenn du das eigene Chart-Widget weiter nutzt, lass es stehen.
// import '../widgets/simple_line_chart.dart';
// Nur das Modell importieren:
import '../models/sensor_data.dart' show SensorData;
// Charts-Flutter mit Alias behalten
import 'package:charts_flutter/flutter.dart' as charts;
import '../services/ws_service.dart';

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
                   // 1) Liste der rohen Daten zur Kontrolle
                  Expanded(
                    child: ListView(
                      children: _data.map<Widget>((sd) {
                        return ListTile(
                          title: Text(sd.timestamp.toLocal().toString()),
                          subtitle: Text(sd.dataJson.toString()),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2) Ersten Kanal im Chart darstellen
                  SizedBox(
                    height: 200,
                    child: charts.TimeSeriesChart(
                      [
                        charts.Series<SensorData, DateTime>(
                          id: _data.isNotEmpty
                              ? _data.first.dataJson.keys.first
                              : 'Daten',
                          domainFn: (d, _) => d.timestamp,
                          measureFn: (d, _) =>
                              (d.dataJson[d.dataJson.keys.first] as num)
                                  .toDouble(),
                          data: _data,
                        ),
                      ],
                      animate: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

