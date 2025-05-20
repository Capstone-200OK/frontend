import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/important_screen.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:flutter_application_1/screens/file_reservation_screen.dart';
import 'package:flutter_application_1/screens/reservation_list_screen.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

class NavigationDrawerWidget extends StatelessWidget {
  final String username;
  final Function(String) onFolderCreated;
  final List<String> folders;
  final BuildContext scaffoldContext; // scaffold.of(context) 때문에 추가
  final String? preScreen;
  final List<int>? prePathIds;

  const NavigationDrawerWidget({
    Key? key,
    required this.username,
    required this.onFolderCreated,
    required this.folders,
    required this.scaffoldContext,
    this.preScreen,
    this.prePathIds,
  }) : super(key: key);

  // 로그아웃 함수
  void _logout(BuildContext context) {
    WebSocketService().disconnect();
    Provider.of<UserProvider>(context, listen: false).clearUser();
    NavigationStack.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
  }

  // 회원탈퇴 함수
  void _deleteAccount(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('회원 탈퇴'),
            content: const Text('정말 탈퇴하시겠습니까?\n탈퇴하면 모든 정보가 삭제됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // 아니오
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // 예
                child: const Text('예'),
              ),
            ],
          ),
    );

    // 사용자가 "예"를 눌렀을 때만 탈퇴 진행
    if (shouldDelete == true) {
      final url = dotenv.get("BaseUrl");
      final userId = Provider.of<UserProvider>(context, listen: false).userId;

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        return;
      }

      final deleteUrl = Uri.parse('$url/user/delete/$userId');

      try {
        final response = await http.delete(deleteUrl);

        if (response.statusCode == 200) {
          _logout(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원 탈퇴 완료')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원 탈퇴 실패')));
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        color: const Color(0xFF455A64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 상단 사용자 정보
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: const Color(0xFF455A64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF455A64),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'APPLESDGOTHICNEOEB',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
            ListTile(
              leading: const Icon(
                Icons.star_border,
                color: Colors.white,
                size: 16,
              ),
              title: const Text(
                '중요문서함',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                if (prePathIds != null) {
                  NavigationStack.pop();
                  if (preScreen == 'CLOUD') {
                    NavigationStack.push('CloudScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  else if (preScreen == 'PERSONAL') {
                    NavigationStack.push('PersonalScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  NavigationStack.printStack();
                }
                NavigationStack.push('ImportantScreen', arguments: {'username': username});
                NavigationStack.printStack();
                Navigator.pushReplacement(
                  scaffoldContext,
                  MaterialPageRoute(
                    builder: (context) => ImportantScreen(username: username),
                  ),
                );
              },
              visualDensity: VisualDensity(vertical: -4),
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white, size: 16),
              title: const Text(
                '휴지통',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                if (prePathIds != null) {
                  NavigationStack.pop();
                  if (preScreen == 'CLOUD') {
                    NavigationStack.push('CloudScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  else if (preScreen == 'PERSONAL') {
                    NavigationStack.push('PersonalScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  NavigationStack.printStack();
                }
                NavigationStack.push('TrashScreen', arguments: {'username': username});
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrashScreen(username: username),
                  ),
                );
                NavigationStack.printStack();
              },
              visualDensity: VisualDensity(vertical: -4),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white, size: 16),
              title: const Text(
                'SORTY 목록',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                if (prePathIds != null) {
                  NavigationStack.pop();
                  if (preScreen == 'CLOUD') {
                    NavigationStack.push('CloudScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  else if (preScreen == 'PERSONAL') {
                    NavigationStack.push('PersonalScreen2', arguments: {
                    'username': username,
                    'targetPathIds': prePathIds,
                    });
                  }
                  NavigationStack.printStack();
                }
                final userId = Provider.of<UserProvider>(context, listen: false).userId;
                NavigationStack.push('RecentFileScreen', arguments: {'username': username, 'userId': userId});
                NavigationStack.printStack();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RecentFileScreen(
                          username: username,
                          userId: userId,
                        ),
                  ),
                );

                // print('최근 항목 눌림');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.white, size: 16),
              title: const Text(
                '예약하기',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                showDialog(
                  context: scaffoldContext,
                  builder: (context) => const FileReservationScreen(mode: 'create'),
                );
              },
              visualDensity: VisualDensity(vertical: -4),
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.white, size: 16),
              title: const Text(
                '예약목록',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                showDialog(
                  context: scaffoldContext,
                  builder: (context) => const ReservationListScreen(),
                );
              },
              visualDensity: VisualDensity(vertical: -4),
            ),

            Divider(
              color: Colors.white54, // 색은 살짝 연하게
              thickness: 0.5, // 선 굵기
              indent: 12, // 왼쪽 여백
              endIndent: 12, // 오른쪽 여백
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.white, size: 16),
              title: Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                  height: 1.5,
                ),
              ),
              visualDensity: VisualDensity(vertical: -4), // ✅ 간격 줄이기
              onTap: () => _logout(context),
            ),
            ListTile(
              leading: Icon(Icons.person_remove, color: Colors.white, size: 16),
              title: Text(
                '회원탈퇴',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ),
              ),
              visualDensity: VisualDensity(vertical: -4), // ✅ 간격 줄이기
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
