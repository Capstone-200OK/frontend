import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IOWebSocketChannel? _channel;
  int? _connectedUserId;
  bool get isConnected => _channel != null;

  void connect(BuildContext context, int newUserId) {
    // ✅ 같은 유저로 이미 연결된 경우: 재연결 불필요
    if (_connectedUserId == newUserId && isConnected) {
    //   print('[WebSocket] 이미 연결된 userId=$newUserId');
      return;
    }

    // ✅ 다른 유저로 이미 연결된 경우: 기존 연결 종료
    if (_connectedUserId != null && _connectedUserId != newUserId) {
      disconnect();
    }

    try {
      _channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');
      _connectedUserId = newUserId;

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        final int userIdFromServer = data['userId'];
        final String content = data['message'];
        print(content);

        if (userIdFromServer == _connectedUserId) {
        globalNotificationProvider.addNotification(content); // ✅ 안전하게 처리
        }
      }, onError: (error) {
        print('[WebSocket] 오류: $error');
        _connectedUserId = null;
      }, onDone: () {
        print('[WebSocket] 연결 종료');
        _connectedUserId = null;
      });

      print('[WebSocket] 연결 성공: userId=$_connectedUserId');
    } catch (e) {
      print('[WebSocket] 연결 실패: $e');
      _connectedUserId = null;
    }
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
    print('[WebSocket] 연결 해제');
  }
}
