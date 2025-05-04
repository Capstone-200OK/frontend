import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/important_file_item.dart';
import 'package:flutter_application_1/models/important_folder_item.dart';
import 'package:flutter_application_1/api/important.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImportantScreen extends StatefulWidget {
  final String username;
  const ImportantScreen({super.key, required this.username});

  @override
  State<ImportantScreen> createState() => _ImportantScreenState();
}

class _ImportantScreenState extends State<ImportantScreen> {
  late int? userId;
  List<ImportantFileItem> importantFiles = [];
  List<ImportantFolderItem> importantFolders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      await fetchImportantItems();
    });
  }

  Future<void> fetchImportantItems() async {
    if (userId == null) return;
    final files = await fetchImportantFiles(userId!);
    final folders = await fetchImportantFolders(userId!);

    setState(() {
      importantFiles = files;
      importantFolders = folders;
    });
  }

  Future<List<Map<String, dynamic>>> fetchFolderPath(int folderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/folder/path/$folderId'));

      if (response.statusCode == 200) {
        print('폴더 경로 응답: ${response.body}');
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        final pathList = jsonList.map((e) {
          if (e is Map<String, dynamic>) {
            return {
              "folderId": e["folderId"],
              "folderName": e["folderName"]
            };
          } else {
            throw Exception("Unexpected data format: $e");
          }
        }).toList();

        return pathList;
      } else {
        throw Exception('HTTP 상태 오류: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('❗ fetchFolderPath 실패: $e');
      print('📌 Stack trace: $stack');
      throw Exception('폴더 경로 조회 실패');
    }
  }

  void _showContextMenu({
    required BuildContext context,
    required Offset position,
    required VoidCallback onRemove,
  }) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, overlay.size.width - position.dx, overlay.size.height - position.dy),
      items: [
        PopupMenuItem(
          value: 'remove',
          child: Text('중요 문서함에서 제거', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR')),
        ),
      ],
    ).then((value) {
      if (value == 'remove') {
        onRemove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: NavigationDrawerWidget(
        username: widget.username,
        onFolderCreated: (_) {},
        folders: const [],
        scaffoldContext: context,
        showUploadButton: false,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              const SizedBox(width: 22),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xff263238)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xff263238), size: 15),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.username}님의 중요 문서함',
                  style: const TextStyle(fontSize: 18, fontFamily: 'APPLESDGOTHICNEOEB'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    '중요 폴더',
                    style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                  ),
                ),
                Expanded(
                  child: Text(
                    '중요 파일',
                    style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // 폴더
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: importantFolders.isEmpty
                          ? const Center(child: Text('중요한 폴더가 없습니다.'))
                          : ListView.builder(
                              itemCount: importantFolders.length,
                              itemBuilder: (context, index) {
                                final folder = importantFolders[index];
                                return GestureDetector(
                                  onTap: () async {
                                    final path = await fetchFolderPath(folder.folderId); // API 호출
                                    final pathIds = path.map((p) => p['folderId'] as int).toList();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PersonalScreen(
                                          username: widget.username,
                                          targetPathIds: pathIds, // 루트 → A → B 순서대로 전달
                                        ),
                                      ),
                                    );
                                  },
                                  onSecondaryTapDown: (details) {
                                    _showContextMenu(
                                      context: context,
                                      position: details.globalPosition,
                                      onRemove: () async {
                                        await removeFromImportant(folder.importantId);
                                        await fetchImportantItems();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${folder.folderName} 폴더가 중요 문서함에서 삭제되었습니다.')),
                                        );
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: const Icon(Icons.folder, color: Colors.black54),
                                    title: Text(folder.folderName),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 파일
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: importantFiles.isEmpty
                          ? const Center(child: Text('중요한 파일이 없습니다.'))
                          : ListView.builder(
                              itemCount: importantFiles.length,
                              itemBuilder: (context, index) {
                                final file = importantFiles[index];
                                return GestureDetector(
                                  onSecondaryTapDown: (details) {
                                    _showContextMenu(
                                      context: context,
                                      position: details.globalPosition,
                                      onRemove: () async {
                                        await removeFromImportant(file.importantId);
                                        await fetchImportantItems();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${file.fileName} 파일이 중요 문서함에서 삭제되었습니다.')),
                                        );
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: const Icon(Icons.insert_drive_file, color: Colors.black54),
                                    title: Text(file.fileName),
                                    subtitle: Text('${file.fileType} • ${(file.size / 1024).toStringAsFixed(1)} KB'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 800,
              child: TextField(
                style: const TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                decoration: InputDecoration(
                  hintText: 'search',
                  hintStyle: const TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                  filled: true,
                  fillColor: const Color(0xFFCFD8DC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF607D8B), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xff263238)),
                  suffixIcon: const Icon(Icons.tune, color: Color(0xff263238)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
