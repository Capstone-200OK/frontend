import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/trash_screen.dart';
import 'package:flutter_application_1/screens/file_reservation_screen.dart';
import 'package:flutter_application_1/api/folder_create.dart';

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
          ],
        ),
      ),
    );
  }
}
