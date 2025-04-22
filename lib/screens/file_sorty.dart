import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class FileSortyScreen extends StatefulWidget {
  final List<FolderItem> folders;  // 폴더 리스트로 변경
  final String username;
  final List<int> sourceFolderIds;
  final int destinationFolderId;

  const FileSortyScreen({
    super.key,
    required this.folders,  // 폴더 리스트 받기
    required this.username,
    required this.sourceFolderIds,
    required this.destinationFolderId,
  });

  @override
  State<FileSortyScreen> createState() => _FileSortyScreenState();
}

class _FileSortyScreenState extends State<FileSortyScreen> {
  String? selectedMode;
  late String url;
  FolderItem? selectedDestinationFolder;
  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
        height: 500,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListView(
          children: [
            // 타이틀 영역
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF45525B),
              ),
              child: const Center(
                child: Text(
                  '폴더 정리를 시작합니다!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 본문 레이아웃: 좌우 분할
            SizedBox(
              height: 400,
              child: Row(
                children: [
                  // 왼쪽: 선택된 폴더 리스트
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '선택된 폴더',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.folders.length,
                              itemBuilder: (context, index) {
                                final folder = widget.folders[index];
                                return ListTile(
                                  title: Text(folder.name),
                                  leading: const Icon(Icons.folder),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: IconButton(
                              onPressed: () {
                                print("폴더 추가!");
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              iconSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                    // 오른쪽: 목적지 폴더 + 정리 기준 + 정리하기 버튼
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ① 목적지 폴더 표시
                            const Text(
                              '목적지 폴더',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.folder, color: Color(0xFF45525B)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedDestinationFolder?.name ?? "폴더를 선택해주세요",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () async {
                                      final result = await showDialog<FolderItem>(
                                        context: context,
                                        builder: (context) => const FolderSelectDialog(),  // 폴더 선택 팝업 호출
                                      );
                                      if (result != null) {
                                        setState(() {
                                          selectedDestinationFolder = result;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ② 정리 기준 선택
                            const Text(
                              '정리 기준을 선택해 주세요!',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _sortButton(context, '내용', 'content'),
                                _sortButton(context, '제목', 'title'),
                                _sortButton(context, '날짜', 'date'),
                                _sortButton(context, '유형', 'type'),
                              ],
                            ),

                            const Spacer(),

                            // ③ 정리하기 버튼
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF45525B),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (selectedMode == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('정렬 기준을 선택해 주세요.'),
                                      ),
                                    );
                                    return;
                                  }

                                  final response = await http.post(
                                    Uri.parse('$url/organize/start'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      "folderIds": widget.sourceFolderIds,
                                      "mode": selectedMode,
                                      "destinationFolderId": selectedDestinationFolder!.id,
                                    }),
                                  );

                                  Navigator.of(context).pop();

                                  if (response.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('자동 정리가 시작되었습니다.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('정리 요청 실패: ${response.statusCode}')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                                label: const Text('정리하기', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
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

  Widget _sortButton(BuildContext context, String label, String mode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedMode == mode ? Colors.black : Colors.white,
        foregroundColor: selectedMode == mode ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          selectedMode = mode;
        });
      },
      child: Text(label),
    );
  }
}

class FolderSelectDialog extends StatefulWidget {
  const FolderSelectDialog({Key? key}) : super(key: key);

  @override
  State<FolderSelectDialog> createState() => _FolderSelectDialogState();
}

class _FolderSelectDialogState extends State<FolderSelectDialog> {
  List<FolderItem> currentFolders = [];
  List<int> folderStack = [];
  FolderItem? selected;

  late String url;

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    loadFolders(1); // 루트 폴더 ID
  }

  Future<void> loadFolders(int folderId) async {
    final response = await http.get(
      Uri.parse('$url/folder/hierarchy/$folderId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final subFolders = List<Map<String, dynamic>>.from(data['subFolders']);
      setState(() {
        currentFolders = subFolders
            .map((f) => FolderItem(id: f['id'], name: f['name']))
            .toList();

        if (folderStack.isEmpty || folderStack.last != folderId) {
          folderStack.add(folderId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (folderStack.length > 1)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (folderStack.length > 1) {
                  folderStack.removeLast();
                  loadFolders(folderStack.last);
                }
              },
            ),
          const Text("폴더 선택"),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: currentFolders.length,
          itemBuilder: (context, index) {
            final folder = currentFolders[index];
            final isSelected = selected?.id == folder.id;

            return GestureDetector(
              onTap: () => setState(() => selected = folder),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => setState(() => selected = folder),
                    ),
                    const Icon(Icons.folder, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folder.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => loadFolders(folder.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("취소"),
        ),
        ElevatedButton(
          onPressed: selected != null
              ? () => Navigator.pop(context, selected)
              : null,
          child: const Text("확인"),
        ),
      ],
    );
  }
}
