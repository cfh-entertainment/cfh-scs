import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/device.dart';

class DeviceListScreen extends StatefulWidget {
  final String serverIp;

  const DeviceListScreen({super.key, required this.serverIp});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<Device> devices = [];
  late WebSocketChannel wsChannel;
  bool isWsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final uri = Uri.parse('ws://${widget.serverIp}:3000');
    wsChannel = WebSocketChannel.connect(uri);

    wsChannel.stream.listen((event) {
      final data = json.decode(event);
      if (data['topic'] != null && data['topic'].toString().contains('/status')) {
        final parts = data['topic'].toString().split('/');
        if (parts.length >= 3) {
          final deviceId = parts[1];
          final status = data['message'];

          setState(() {
            // Gerät anhand name (deviceId) finden und aktualisieren
            for (var d in devices) {
              if (d.name == deviceId) {
                d.status = status; // Nur möglich wenn status `late` oder `var`
              }
            }
          });
        }
      }
    }, onError: (e) {
      debugPrint('WebSocket-Fehler: $e');
    });
  }

  @override
  void dispose() {
    wsChannel.sink.close();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final uri = Uri.parse('http://${widget.serverIp}:3000/api/v1/devices');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        devices = List<Device>.from(data.map((d) => Device.fromJson(d)));
      });
    } else {
      debugPrint('❌ Fehler beim Laden: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = <int?, List<Device>>{};

    for (final d in devices) {
      areas[d.areaId] = [...(areas[d.areaId] ?? []), d];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Geräte nach Bereich')),
      body: ListView(
        children: areas.entries.map((entry) {
          final areaName = entry.key == null
              ? '❓ Unzugewiesen'
              : entry.value.first.areaName ?? 'Unbekannt';

          return ExpansionTile(
            title: Text(areaName),
            children: entry.value.map((d) {
              final statusColor =
                  d.status == 'online' ? Colors.green : Colors.red;
              return ListTile(
                title: Text(d.name),
                trailing: Icon(Icons.circle, color: statusColor, size: 14),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
