import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/trash_file_item.dart';
import 'package:flutter_application_1/models/trash_folder_item.dart';
import 'package:flutter_application_1/api/trash.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

class TrashScreen extends StatefulWidget {
  final String username;
  const TrashScreen({super.key, required this.username});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late int? userId;
  List<TrashFileItem> deletedFiles = [];
  List<TrashFolderItem> deletedFolders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      await fetchTrashItems();
    });
  }

  Future<void> fetchTrashItems() async {
    if (userId == null) return;
    final files = await fetchDeletedFiles(userId!);
    final folders = await fetchDeletedFolders(userId!);

    setState(() {
      deletedFiles = files;
      deletedFolders = folders;
    });
  }

  void _showContextMenu({
    required BuildContext context,
    required Offset position,
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, overlay.size.width - position.dx, overlay.size.height - position.dy),
      items: [
        PopupMenuItem(
          value: 'restore',
          child: Text('복원하기', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('삭제하기', style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR')),
        ),
      ],
    ).then((value) {
      if (value == 'restore') {
        onRestore();
      } else if (value == 'delete') {
        onDelete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: NavigationDrawerWidget(
        username: widget.username,
        onFolderCreated: (folderName) {
        // 필요 시 폴더 생성 후 작업 추가
        },
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
                  '${widget.username}님의 휴지통',
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
                    '삭제된 폴더',
                    style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                  ),
                ),
                Expanded(
                  child: Text(
                    '삭제된 파일',
                    style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOEB'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // 폴더 영역
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
                                return GestureDetector(
                                  onSecondaryTapDown: (details) {
                                    _showContextMenu(
                                      context: context,
                                      position: details.globalPosition,
                                      onRestore: () async {
                                        await restoreFromTrash([folder.trashId]);
                                        await fetchTrashItems();
                                      },
                                      onDelete: () async {
                                        await deleteFromTrash([folder.trashId]);
                                        await fetchTrashItems();
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
                  // 파일 영역
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
                                return GestureDetector(
                                  onSecondaryTapDown: (details) {
                                    _showContextMenu(
                                      context: context,
                                      position: details.globalPosition,
                                      onRestore: () async {
                                        await restoreFromTrash([file.trashId]);
                                        await fetchTrashItems();
                                      },
                                      onDelete: () async {
                                        await deleteFromTrash([file.trashId]);
                                        await fetchTrashItems();
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
            // 검색창
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
