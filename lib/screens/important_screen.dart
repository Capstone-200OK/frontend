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
import 'dart:async';
import 'package:flutter_application_1/screens/file_view_dialog.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

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
  final GlobalKey _previewKey = GlobalKey();
  OverlayEntry? _previewOverlay;
  Timer? _hoverTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      await fetchImportantItems();
    });
  }

  Widget _buildPreviewContent(String url, String type, {String? thumbnailUrl}) {
    final lower = type.toLowerCase();

    if (["png", "jpg", "jpeg", "gif", "bmp"].contains(lower)) {
      return Image.network(url, fit: BoxFit.contain);
    }

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(thumbnailUrl, fit: BoxFit.contain);
    }

    if (lower == "pdf") {
      return SfPdfViewer.network(url);
    } else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(lower)) {
      return OfficeViewerWindows(fileUrl: url);
    }

    return const Center(child: Text("미리보기를 지원하지 않는 형식입니다."));
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
      final response = await http.get(
        Uri.parse('$baseUrl/folder/path/$folderId'),
      );

      if (response.statusCode == 200) {
        print('폴더 경로 응답: ${response.body}');
        final List<dynamic> jsonList = jsonDecode(response.body);

        final pathList =
            jsonList.map((e) {
              if (e is Map<String, dynamic>) {
                return {
                  "folderId": e["folderId"],
                  "folderName": e["folderName"],
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

  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
  }

  void _showContextMenu({
    required BuildContext context,
    required Offset position,
    required VoidCallback onRemove,
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
          value: 'remove',
          child: Text(
            '중요 문서함에서 제거',
            style: TextStyle(fontFamily: 'APPLESDGOTHICNEOR'),
          ),
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

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const SizedBox(width: 70),
              IconButton(
                icon: const Icon(Icons.home, color: Color(0xff263238)),
                onPressed: () {
                  NavigationStack.clear();
                  NavigationStack.push('HomeScreen', arguments: {'username': widget.username});
                  NavigationStack.printStack();
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
                onPressed: () => NavigationHelper.navigateToPrevious(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.username}님의 중요 문서함',
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
                      '중요 폴더',
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
                      '중요 파일',
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
                            importantFolders.isEmpty
                                ? const Center(child: Text('중요한 폴더가 없습니다.'))
                                : ListView.builder(
                                  itemCount: importantFolders.length,
                                  itemBuilder: (context, index) {
                                    final folder = importantFolders[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        final path = await fetchFolderPath(
                                          folder.folderId,
                                        );
                                        final pathIds =
                                            path
                                                .map(
                                                  (p) => p['folderId'] as int,
                                                )
                                                .toList();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => PersonalScreen(
                                                  username: widget.username,
                                                  targetPathIds: pathIds,
                                                ),
                                          ),
                                        );
                                      },
                                      onSecondaryTapDown: (details) {
                                        _showContextMenu(
                                          context: context,
                                          position: details.globalPosition,
                                          onRemove: () async {
                                            await removeFromImportant(
                                              folder.importantId,
                                            );
                                            await fetchImportantItems();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${folder.folderName} 폴더가 중요 문서함에서 삭제되었습니다.',
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
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
                          importantFiles.isEmpty
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
                                          await removeFromImportant(
                                            file.importantId,
                                          );
                                          await fetchImportantItems();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${file.fileName} 파일이 중요 문서함에서 삭제되었습니다.',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
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
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (_) => FilePreviewDialog(
                                                  fileUrl: file.fileUrl!,
                                                  fileType: file.fileType,
                                                ),
                                          );
                                        },
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
            //검색창
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
