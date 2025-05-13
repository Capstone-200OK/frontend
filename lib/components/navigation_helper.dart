import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/screens/important_screen.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';

class NavigationHelper {
  static void navigateToPrevious(BuildContext context) {
    final previous = NavigationStack.getPrevious();
    if (previous != null) {
      final route = previous['route'];
      final args = previous['arguments'];

      Widget targetScreen;

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
        // 예외: 이동할 화면 없음 → 홈으로
        targetScreen = HomeScreen(username: args['username'] ?? 'Guest');
      }

      // ⭐ NavigationStack의 현재 화면 pop
      NavigationStack.pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    }
  }
}
