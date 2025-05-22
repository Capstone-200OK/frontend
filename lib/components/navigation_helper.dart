import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/screens/important_screen.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';

/// 화면 이동을 도와주는 헬퍼 클래스
class NavigationHelper {
  // 이전 화면으로 이동하는 정적 메서드
  static void navigateToPrevious(BuildContext context) {
    final previous = NavigationStack.getPrevious(); // 스택에서 이전 화면 정보 가져오기
    if (previous != null) {
      final route = previous['route']; // 이전 화면 이름
      final args = previous['arguments']; // 이전 화면에 전달된 인자들

      Widget targetScreen;

      // 이전 화면 경로(route)에 따라 해당 화면으로 이동
      if (route == 'TrashScreen') {
        targetScreen = TrashScreen(username: args['username']);
      } else if (route == 'HomeScreen') {
        targetScreen = HomeScreen(username: args['username']);
      } else if (route == 'RecentFileScreen') {
        targetScreen = RecentFileScreen(
          username: args['username'],
          userId: args['userId'],
        );
      } else if (route == 'PersonalScreen1') {
        targetScreen = PersonalScreen(
          username: args['username'],
        );
      } else if (route == 'PersonalScreen2') {
        targetScreen = PersonalScreen(
          username: args['username'],
          targetPathIds: args['targetPathIds'],
        );
      } else if (route == 'SearchPersonalScreen') {
        targetScreen = PersonalScreen(
          username: args['username'],
          targetPathIds: args['targetPathIds'],
        );
      } else if (route == 'CloudScreen1') {
        targetScreen = CloudScreen(
          username: args['username'],
        );
      } else if (route == 'CloudScreen2') {
        targetScreen = CloudScreen(
          username: args['username'],
          targetPathIds: args['targetPathIds'],
        );
      } else if (route == 'SearchCloudScreen') {
        targetScreen = CloudScreen(
          username: args['username'],
          targetPathIds: args['targetPathIds'],
        );
      } else {
        // 예외 처리: 이전 화면 정보가 없을 경우 홈 화면으로 이동
        targetScreen = HomeScreen(username: args['username'] ?? 'Guest');
      }

      // 현재 화면을 NavigationStack에서 제거
      NavigationStack.pop();

      // 이전 화면으로 교체(pushReplacement)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    }
  }
}
