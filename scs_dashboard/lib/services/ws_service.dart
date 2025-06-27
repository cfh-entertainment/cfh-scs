// lib/services/ws_service.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef DeviceCreatedCallback = void Function(Map<String, dynamic> device);
typedef DeviceUpdatedCallback = void Function(Map<String, dynamic> device);
typedef DeviceDeletedCallback = void Function(int id);

class WSService {
  late IO.Socket _socket;

  void connect(String ip,
      {required DeviceCreatedCallback onCreated,
       required DeviceUpdatedCallback onUpdated,
       required DeviceDeletedCallback onDeleted}) {
    final uri = 'http://$ip:3000';
    _socket = IO.io(uri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('WS verbunden');
    });
    _socket.on('deviceCreated', (data) => onCreated(data as Map<String, dynamic>));
    _socket.on('deviceUpdated', (data) => onUpdated(data as Map<String, dynamic>));
    _socket.on('deviceDeleted', (data) {
      final map = data as Map<String, dynamic>;
      final rawId = map['id'];
      final id = rawId is int
        ? rawId
        : int.tryParse(rawId.toString()) ?? 0;
      onDeleted(id);
    });
  }

  void disconnect() {
    _socket.disconnect();
  }
}
