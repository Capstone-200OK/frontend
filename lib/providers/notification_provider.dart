import 'package:flutter/material.dart';

/// 알림 상태를 관리하는 Provider 클래스
// 알림 추가, 삭제, 읽음 처리 등의 기능을 제공
class NotificationProvider extends ChangeNotifier {
  final List<String> _notifications = []; // 알림 메시지를 저장하는 리스트
  bool _hasUnread = false; // 읽지 않은 알림이 있는지 여부

  // 외부에서 알림 목록을 읽을 수 있도록 제공 (수정은 불가)
  List<String> get notifications => List.unmodifiable(_notifications);
  
  // 읽지 않은 알림이 있는지 여부 반환
  bool get hasUnread => _hasUnread;

  // 알림 추가 시 호출되는 메서드
  void addNotification(String message) {
    _notifications.add(message); // 새 알림 추가
    _hasUnread = true; // 읽지 않음 상태로 설정
    notifyListeners(); // 상태 변경 알림 → UI 갱신
  }

  // 특정 인덱스의 알림을 제거
  void removeNotification(int index) {
    _notifications.removeAt(index); // 해당 인덱스 알림 삭제
    if (_notifications.isEmpty) _hasUnread = false; // 알림이 없으면 읽지 않음도 해제
    notifyListeners(); // 상태 변경 알림
  }

  // 모든 알림을 읽음 처리
  void markAllAsRead() {
    _hasUnread = false; // 읽지 않음 상태 해제
    notifyListeners(); // 상태 변경 알림
  }
}