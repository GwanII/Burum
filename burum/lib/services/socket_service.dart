import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void connect(String baseUrl, int userId) {
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('소켓 연결 성공');
      socket!.emit('joinUser', userId);
    });

    socket!.onDisconnect((_) {
      print('소켓 연결 해제');
    });

    socket!.onConnectError((data) {
      print('소켓 연결 에러: $data');
    });

    socket!.onError((data) {
      print('소켓 에러: $data');
    });
  }

  void joinRoom(int roomId) {
    socket?.emit('joinRoom', roomId);
  }

  void leaveRoom(int roomId) {
    socket?.emit('leaveRoom', roomId);
  }

  void on(String event, Function(dynamic) handler) {
    socket?.off(event);
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void dispose() {
    socket?.dispose();
    socket = null;
  }
}