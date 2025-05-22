import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';
import 'package:provider/provider.dart';

/// WebSocket 연결을 관리하는 싱글톤 서비스 클래스
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal(); // 싱글턴 인스턴스
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IOWebSocketChannel? _channel; // WebSocket 채널
  int? _connectedUserId; // 현재 연결된 사용자 ID
  bool get isConnected => _channel != null; // 연결 여부 확인

  // WebSocket 연결 메서드
  void connect(BuildContext context, int newUserId) {
    // ✅ 동일한 사용자로 이미 연결되어 있으면 다시 연결하지 않음
    if (_connectedUserId == newUserId && isConnected) {
      return;
    }

    // ✅ 다른 사용자로 연결된 상태면 기존 연결 해제
    if (_connectedUserId != null && _connectedUserId != newUserId) {
      disconnect();
    }

    try {
      // WebSocket 서버에 연결 시도
      _channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');
      _connectedUserId = newUserId;

      // 서버로부터 오는 메시지 수신
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        final int userIdFromServer = data['userId'];
        final String content = data['message'];
        print(content);

        // 수신한 메시지의 userId가 현재 연결된 사용자와 일치할 경우에만 처리
        if (userIdFromServer == _connectedUserId) {
        globalNotificationProvider.addNotification(content); // 알림 추가
        }
      }, onError: (error) {
        // 에러 발생 시 로그 출력 및 연결 상태 초기화
        print('[WebSocket] 오류: $error');
        _connectedUserId = null;
      }, onDone: () {
        // 서버와의 연결이 종료되었을 때 처리
        print('[WebSocket] 연결 종료');
        _connectedUserId = null;
      });

      print('[WebSocket] 연결 성공: userId=$_connectedUserId');
    } catch (e) {
      // 연결 실패 시 예외 처리
      print('[WebSocket] 연결 실패: $e');
      _connectedUserId = null;
    }
  }

  // WebSocket 연결 해제 메서드
  void disconnect() {
    _channel?.sink.close(status.goingAway); // 서버에 정상 종료 알림
    _channel = null;
    print('[WebSocket] 연결 해제');
  }
}
