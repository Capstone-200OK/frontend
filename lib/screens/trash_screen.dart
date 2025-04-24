import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'package:flutter_application_1/api/trash.dart';

List<FileItem> deletedFolders = []; // 삭제된 폴더 목록
List<FileItem> selectedFolders = []; // 선택된 폴더 목록
List<FileItem> deletedFiles = []; // 삭제된 파일 목록
List<FileItem> selectedFiles = []; // 선택된 파일 목록

class TrashScreen extends StatefulWidget {
  final String username;
  const TrashScreen({super.key, required this.username});

  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {

  // 복원 로직: 파일 복원
  void restoreFile(FileItem file) {
    setState(() {
      deletedFiles.remove(file); // 삭제된 파일 목록에서 해당 파일 제거
      selectedFiles.add(file); // 복원된 파일 목록에 파일 추가
      print('복원된 파일: ${file.name}');
    });
  }

  // 복원 로직: 폴더 복원
  void restoreFolder(FileItem folder) {
    setState(() {
      deletedFolders.remove(folder); // 삭제된 폴더 목록에서 해당 폴더 제거
      selectedFolders.add(folder); // 복원된 폴더 목록에 폴더 추가
      print('복원된 폴더: ${folder.name}');
    });
  }

  // 폴더 삭제 처리
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        elevation: 0,
        title: const Text(
          '휴지통',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'APPLESDGOTHICNEOR',
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    '삭제된 폴더',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'APPLESDGOTHICNEOEB',
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '삭제된 파일',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'APPLESDGOTHICNEOEB',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  // 삭제된 폴더 영역
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: deletedFolders.isEmpty
                          ? const Center(child: Text('삭제된 폴더가 없습니다.'))
                          : ListView.builder(
                              itemCount: deletedFolders.length,
                              itemBuilder: (context, index) {
                                final folder = deletedFolders[index];
                                return ListTile(
                                  leading: const Icon(Icons.folder, color: Colors.black54),
                                  title: Text(folder.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.restore),
                                    onPressed: () {
                                      restoreFolder(folder); // 폴더 복원 로직 호출
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 삭제된 파일 영역
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: deletedFiles.isEmpty
                          ? const Center(child: Text('삭제된 파일이 없습니다.'))
                          : ListView.builder(
                            itemCount: deletedFiles.length,
                            itemBuilder: (context, index) {
                              final file = deletedFiles[index];
                              return ListTile(
                                leading: const Icon(Icons.insert_drive_file, color: Colors.black54),
                                title: Text(file.name),
                                subtitle: Text('${file.type} • ${(file.sizeInBytes / 1024).toStringAsFixed(1)} KB'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.restore),
                                  onPressed: () {
                                    restoreFile(file); // 복원 로직 호출
                                  },
                                ),
                              );
                            },
                          ),
                    
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}