import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/ws_service.dart';
import 'sensor_detail_screen.dart';
import 'users/user_list_screen.dart';
import 'rules/rule_list_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'logs/log_list_screen.dart';
import 'devices/device_list_screen.dart';
import '../models/device.dart';
import 'package:provider/provider.dart';
import '../../theme_manager.dart';

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
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://${widget.ip}:3000/api/v1';
    _deviceService = DeviceService(baseUrl);
    _wsService = WSService();
    _auth = AuthService(baseUrl);

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
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text('Dashboard'),
          ],
        ),
        actions: [
          // Darkmode-Schalter
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Dark Mode umschalten',
            onPressed: () =>
              Provider.of<ThemeManager>(context, listen: false).toggle(),
          ),

          // Geräteverwaltung
          IconButton(
            icon: const Icon(Icons.devices),
            tooltip: 'Geräte verwalten',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DeviceListScreen(ip: widget.ip)),
            ),
          ),

          // Regeln verwalten
          IconButton(
            icon: const Icon(Icons.rule_folder),
            tooltip: 'Regeln verwalten',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RuleListScreen(ip: widget.ip)),
            ),
          ),

          // User-Verwaltung
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'User-Verwaltung',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserListScreen(ip: widget.ip),
              ),
            ),
          ),

          // Logout-Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () async {
              // JWT löschen
              await _auth.logout();
              // zurück zum Login-Screen, alle bisherigen Routen entfernen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SensorDetailScreen(
                          ip: widget.ip,
                          deviceId: dev.id,
                          deviceName: dev.deviceId,
                        ),
                      ),
                    );
                  },

                  // Logs-Button
                  trailing: IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Logs',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LogListScreen(
                          ip: widget.ip,
                          deviceId: dev.id,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
