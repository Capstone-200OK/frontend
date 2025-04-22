import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';  // PersonalScreen import 추가

class FileBack extends StatelessWidget {
  final String currentFolderName;
  final int currentFolderId;
  final Function fetchFolderHierarchy;
  final String username;

  const FileBack({
    Key? key,
    required this.currentFolderName,
    required this.currentFolderId,
    required this.fetchFolderHierarchy,
    required this.username, // 전달받은 username 필드
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            fetchFolderHierarchy(currentFolderId - 1);
          },
        ),
        Text('ROOT > $currentFolderName'),
        // username을 출력하는 예시:
        Text('User: $username'),
        IconButton(
          icon: const Icon(Icons.navigate_next),
          onPressed: () {
            // PersonalScreen으로 넘어갈 때 username 전달
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalScreen(username: username),  // username을 전달
              ),
            );
          },
        ),
      ],
    );
  }
}
