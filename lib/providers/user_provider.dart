import 'package:flutter/material.dart';

/// 사용자 ID를 관리하는 Provider 클래스
// 로그인/로그아웃 시 userId를 설정하거나 초기화함
class UserProvider with ChangeNotifier {
  int? _userId; // 현재 로그인한 사용자의 ID (nullable)

  // 현재 사용자 ID 반환 (null일 수 있음)
  int? get userId => _userId;

  // 사용자 ID 설정 (로그인 시 사용)
  void setUserId(int id) {
    _userId = id;
    notifyListeners(); // 상태 변경 알림 → UI 갱신
  }

  // 사용자 정보 초기화 (로그아웃 시 사용)
  void clearUser() {
    _userId = null;
    notifyListeners(); // 상태 변경 알림
  }
}
