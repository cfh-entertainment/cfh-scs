import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/ws_service.dart';

class DashboardScreen extends StatefulWidget {
  final String ip;
  const DashboardScreen({Key? key, required this.ip}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DeviceService _deviceService;
  late WSService _wsService;
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _deviceService = DeviceService(baseUrl);
    _wsService = WSService();

    // 1) Geräte laden
    _loadDevices();

    // 2) WebSocket verbinden
    _wsService.connect(
      widget.ip,
      onCreated: (d) => _addDevice(d),
      onUpdated: (d) => _updateDevice(d),
      onDeleted: (id) => _removeDevice(id),
    );
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final list = await _deviceService.fetchDevices();
    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  void _addDevice(Map<String, dynamic> d) {
    setState(() {
      _devices.add(Device.fromJson(d));
    });
  }

  void _updateDevice(Map<String, dynamic> d) {
    final updated = Device.fromJson(d);
    setState(() {
      _devices = _devices.map((dev) => dev.id == updated.id ? updated : dev).toList();
    });
  }

  void _removeDevice(int id) {
    setState(() {
      _devices.removeWhere((dev) => dev.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, i) {
                final dev = _devices[i];
                return ListTile(
                  leading: Icon(Icons.devices),
                  title: Text(dev.deviceId),
                  subtitle: Text('Typ: ${dev.type}\nLetztes Signal: ${dev.lastSeen}'),
                );
              },
            ),
    );
  }
}
