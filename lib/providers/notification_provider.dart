import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final List<String> _notifications = [];
  bool _hasUnread = false;

  List<String> get notifications => List.unmodifiable(_notifications);
  bool get hasUnread => _hasUnread;

  void addNotification(String message) {
    _notifications.add(message);
    _hasUnread = true;
    notifyListeners();
  }

  void removeNotification(int index) {
    _notifications.removeAt(index);
    if (_notifications.isEmpty) _hasUnread = false;
    notifyListeners();
  }

  void markAllAsRead() {
    _hasUnread = false;
    notifyListeners();
  }
}
