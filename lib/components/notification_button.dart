import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';

/// 상단바에 표시되는 알림 아이콘 버튼 위젯
class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      // NotificationProvider의 상태 변화에 따라 UI 갱신
      builder: (context, provider, _) {
        return Stack(
          children: [
            // 기본 알림 아이콘 버튼
            IconButton(
              icon: const Icon(Icons.notifications, color: Color(0xff263238)),
              onPressed: () {
                // 알림 아이콘 클릭 시 알림 다이얼로그 표시
                showDialog(
                  context: context,
                  builder: (_) => StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFFECEFF1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        title: Column(
                          children: [
                            const Icon(Icons.notifications, color: Color(0xff263238), size: 40),
                            const SizedBox(height: 8),
                            const Divider(thickness: 1, color: Colors.black26),
                          ],
                        ),
                        content: provider.notifications.isEmpty
                            // 알림이 없을 경우
                            ? const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text('알림이 없습니다.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: 'APPLESDGOTHICNEOR',
                                          fontSize: 14,
                                          color: Colors.black54)),
                                ),
                              )
                            // 알림이 있을 경우 목록으로 표시
                            : SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: provider.notifications.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            provider.notifications[index],
                                            style: TextStyle(
                                              fontFamily: 'APPLESDGOTHICNEOEB',
                                              fontSize: 18,
                                              color: Colors.black,
                                              ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, size: 25),
                                            onPressed: () {
                                              provider.removeNotification(index); // 알림 개별 삭제
                                              setState(() {}); // 다이얼로그 내에서 즉시 갱신
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 13,),
                                        const Divider(height: 1, thickness: 0.5),
                                      ],
                                    );
                                  },
                                ),
                              ),
                        actions: [
                          // 닫기 버튼 (전체 읽음 처리 후 닫기)
                          TextButton(
                            onPressed: () {
                              provider.markAllAsRead(); // 모든 알림 읽음 처리
                              Navigator.pop(context); // 다이얼로그 닫기
                            },
                            child: const Text('닫기',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'APPLESDGOTHICNEOR',
                                    color: Color(0xFF596D79))),
                          )
                        ],
                      );
                    },
                  ),
                );
                },
            ),
            // 읽지 않은 알림이 있을 경우 빨간 점 표시
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
