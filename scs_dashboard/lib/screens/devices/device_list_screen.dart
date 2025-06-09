import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import 'device_form_screen.dart';

class DeviceListScreen extends StatefulWidget {
  final String ip;
  const DeviceListScreen({Key? key, required this.ip}) : super(key: key);

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late DeviceService _service;
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _service = DeviceService(baseUrl);
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final list = await _service.fetchDevices();
    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  void _onAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeviceFormScreen(ip: widget.ip)),
    );
    _loadDevices();
  }

  void _onEdit(Device d) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeviceFormScreen(ip: widget.ip, device: d)),
    );
    _loadDevices();
  }

  void _onDelete(int id) async {
    await _service.deleteDevice(id);
    _loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geräte-Verwaltung')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (ctx, i) {
                final d = _devices[i];
                return ListTile(
                  title: Text(d.deviceId),
                  subtitle: Text('Typ: ${d.type}'),
                  onTap: () => _onEdit(d),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _onDelete(d.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
