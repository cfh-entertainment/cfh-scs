import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DashboardScreen extends StatefulWidget {
  final String serverIp;

  const DashboardScreen({super.key, required this.serverIp});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late WebSocketChannel channel;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    final wsUrl = 'ws://${widget.serverIp}:3000';
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    channel.stream.listen((data) {
      setState(() {
        messages.insert(0, data);
      });
    }, onError: (e) {
      messages.insert(0, 'Fehler: $e');
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (_, i) => ListTile(title: Text(messages[i])),
      ),
    );
  }
}
