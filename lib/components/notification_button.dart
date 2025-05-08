import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Color(0xff263238)),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) => StatefulBuilder(
                    builder: (context, setState) {
                        return AlertDialog(
                        title: const Text('알림'),
                        content: provider.notifications.isEmpty
                            ? const Text('알림이 없습니다.')
                            : SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: provider.notifications.length,
                                    itemBuilder: (context, index) {
                                    return ListTile(
                                        title: Text(provider.notifications[index]),
                                        trailing: IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () {
                                            provider.removeNotification(index);
                                            setState(() {}); // ✅ 팝업 내부 갱신
                                        },
                                        ),
                                    );
                                    },
                                ),
                                ),
                        actions: [
                            TextButton(
                            onPressed: () {
                                provider.markAllAsRead();
                                Navigator.pop(context);
                            },
                            child: const Text('닫기'),
                            )
                        ],
                        );
                    },
                    ),
                );
                },
            ),
            if (provider.hasUnread)
              const Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        );
      },
    );
  }
}
