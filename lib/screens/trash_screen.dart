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
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 'restore',
          child: Text(
            '복원하기',
            style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            '삭제하기',
            style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR'),
          ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,

          title: Row(
            children: [
              //const Spacer(),
              const SizedBox(width: 70),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xff263238)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => HomeScreen(username: widget.username),
                    ),
                  );
                },
              ),
              const SizedBox(width: 22),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.username}님의 휴지통',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100.0, top: 30.0),
                    child: Text(
                      '삭제된 폴더',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 30.0),
                    child: Text(
                      '삭제된 파일',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Row(
                children: [
                  // 🔹 폴더 영역 (왼쪽 여백 추가됨)
                  Padding(
                    padding: const EdgeInsets.only(left: 97), // 오른쪽으로 밀기
                    child: SizedBox(
                      height: 400,
                      width: 370,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFD8DC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            deletedFolders.isEmpty
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
                                            await restoreFromTrash([
                                              folder.trashId,
                                            ]);
                                            await fetchTrashItems();
                                          },
                                          onDelete: () async {
                                            await deleteFromTrash([
                                              folder.trashId,
                                            ]);
                                            await fetchTrashItems();
                                          },
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ), // 요소 간 간격
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white, // 🔸 각 요소 배경색
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ), // 🔸 둥근 테두리
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ), // 🔸 살짝 그림자
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.folder,
                                            color: Colors.black54,
                                            size: 14,
                                          ),
                                          title: Text(
                                            folder.folderName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'APPLESDGOTHICNEOR',
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 53),

                  // 🔹 파일 영역 (변경 없음)
                  SizedBox(
                    height: 400,
                    width: 370,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          deletedFiles.isEmpty
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
                                          await restoreFromTrash([
                                            file.trashId,
                                          ]);
                                          await fetchTrashItems();
                                        },
                                        onDelete: () async {
                                          await deleteFromTrash([file.trashId]);
                                          await fetchTrashItems();
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ), // 요소 간 간격
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white, // 🔸 흰 배경
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ), // 🔸 은은한 그림자
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.black54,
                                          size: 14,
                                        ),
                                        title: Text(
                                          file.fileName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'APPLESDGOTHICNEOR',
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${file.fileType} • ${(file.size / 1024).toStringAsFixed(1)} KB',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
            ),

            // 검색창
            Padding(
              padding: const EdgeInsets.only(bottom: 48), // 🔸 위쪽 여백 줄여서 위로 올림
              child: SizedBox(
                width: 800,
                child: TextField(
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                  decoration: InputDecoration(
                    hintText: 'search',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'APPLESDGOTHICNEOEB',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFCFD8DC),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Color(0xFF607D8B),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xff263238),
                    ),
                    suffixIcon: const Icon(
                      Icons.tune,
                      color: Color(0xff263238),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
