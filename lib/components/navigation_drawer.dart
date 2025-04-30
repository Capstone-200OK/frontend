import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/file_reservation_screen.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class NavigationDrawerWidget extends StatelessWidget {
  final String username;
  final Function(String) onFolderCreated;
  final List<String> folders;
  final BuildContext scaffoldContext; // scaffold.of(context) 때문에 추가

  const NavigationDrawerWidget({
    Key? key,
    required this.username,
    required this.onFolderCreated,
    required this.folders,
    required this.scaffoldContext,
  }) : super(key: key);

  // 로그아웃 함수
   void _logout(BuildContext context) {
     Provider.of<UserProvider>(context, listen: false).clearUser();
 
     Navigator.pushAndRemoveUntil(
       context,
       MaterialPageRoute(builder: (context) => const LoginScreen()),
       (route) => false,
     );
 
     ScaffoldMessenger.of(context)
         .showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
   }
 
   // 회원탈퇴 함수
   void _deleteAccount(BuildContext context) async {
   final shouldDelete = await showDialog<bool>(
     context: context,
     builder: (context) => AlertDialog(
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
       ScaffoldMessenger.of(context)
           .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
       return;
     }
 
     final deleteUrl = Uri.parse('$url/user/delete/$userId');
 
     try {
       final response = await http.delete(deleteUrl);
 
       if (response.statusCode == 200) {
         _logout(context);
         ScaffoldMessenger.of(context)
             .showSnackBar(const SnackBar(content: Text('회원 탈퇴 완료')));
       } else {
         ScaffoldMessenger.of(context)
             .showSnackBar(const SnackBar(content: Text('회원 탈퇴 실패')));
       }
     } catch (e) {
       print(e);
       ScaffoldMessenger.of(context)
           .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
     }
   }
 }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
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
                  const SizedBox(height: 6),
                  Text(
                    '$username@example.com',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
            // 업로드 메뉴
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.white),
              title: const Text(
                '업로드',
                style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
              tileColor: const Color(0xFF455A64),
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));

                final RenderBox overlay = Overlay.of(scaffoldContext).context.findRenderObject() as RenderBox;
                final RelativeRect position = RelativeRect.fromLTRB(
                  100,
                  210,
                  overlay.size.width - 100,
                  0,
                );

                final selected = await showMenu<String>(
                  context: scaffoldContext,
                  position: position,
                  items: [
                    const PopupMenuItem(
                      value: 'new_folder',
                      child: SizedBox(
                        width: 150,
                        child: Text('새 폴더', style: TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'APPLESDGOTHICNEOR')),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'upload_file',
                      child: Text('파일 업로드', style: TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'APPLESDGOTHICNEOR')),
                    ),
                    const PopupMenuItem(
                      value: 'upload_folder',
                      child: Text('폴더 업로드', style: TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'APPLESDGOTHICNEOR')),
                    ),
                  ],
                  elevation: 8,
                  color: Colors.white,
                );

                if (selected == 'new_folder') {
                  final result = await showDialog(
                    context: scaffoldContext,
                    builder: (context) {
                      return Dialog(
                        child: Container(
                          width: 350,
                          height: 280,
                          color: Colors.white,
                          child: FolderCreateScreen(
                            onCreateFolder: (folderName) {
                              onFolderCreated(folderName);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  );

                  if (result == true) {
                    print('새 폴더 생성 완료');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_border, color: Colors.white),
              title: const Text('중요문서함', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
            ),
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('휴지통', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                Navigator.push(
                  scaffoldContext,
                  MaterialPageRoute(builder: (context) => TrashScreen(username: username)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.white),
              title: const Text('예약하기', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
              tileColor: const Color(0xFF455A64),
              onTap: () {
                Navigator.push(
                  scaffoldContext,
                  MaterialPageRoute(builder: (context) => FileReservationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage, color: Colors.white),
              title: const Text('저장용량', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
              tileColor: const Color(0xFF455A64),
              onTap: () => Navigator.pop(scaffoldContext),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('로그아웃', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
              onTap: () => _logout(context),
            ),
            ListTile(
              leading: Icon(Icons.person_off, color: Colors.white),
              title: Text('회원탈퇴', style: TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'APPLESDGOTHICNEOR')),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
