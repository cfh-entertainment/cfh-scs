// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'device_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String serverIp;

  const DashboardScreen({super.key, required this.serverIp});

  @override
  Widget build(BuildContext context) {
    return DeviceListScreen(serverIp: serverIp);
  }
}
