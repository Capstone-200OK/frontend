import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileSortyScreen extends StatefulWidget {
  final List<FolderItem> folders; // 폴더 리스트로 변경
  final String username;
  final List<int> sourceFolderIds;
  final int destinationFolderId;

  const FileSortyScreen({
    super.key,
    required this.folders, // 폴더 리스트 받기
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
              decoration: BoxDecoration(color: const Color(0xFF37474F)),
              child: const Align(
                alignment: Alignment.centerLeft, // 왼쪽 정렬로 설정
                child: Padding(
                  padding: EdgeInsets.only(left: 16), // 왼쪽 여백 추가
                  child: Text(
                    '당신의 폴더를 자동으로 분류 해드려요!',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'APPLESDGOTHICNEOEB',
                      color: Colors.white,
                    ),
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
                      margin: const EdgeInsets.only(left: 20),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400, // 획 색상
                          width: 1,
                        ), // 획 두께
                      ),

                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft, // 왼쪽 위 정렬
                            child: const Text(
                              '선택된 폴더',
                              style: TextStyle(
                                fontSize: 18,
                                //fontWeight: FontWeight.bold,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
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
                                    selectedDestinationFolder?.name ??
                                        "폴더를 선택해주세요",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () async {
                                    final result = await showDialog<FolderItem>(
                                      context: context,
                                      builder:
                                          (context) =>
                                              const FolderSelectDialog(), // 폴더 선택 팝업 호출
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
                                    "destinationFolderId":
                                        selectedDestinationFolder!.id,
                                  }),
                                );

                                Navigator.of(context).pop();

                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('자동 정리가 시작되었습니다.'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '정리 요청 실패: ${response.statusCode}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.auto_fix_high,
                                color: Colors.white,
                              ),
                              label: const Text(
                                '정리하기',
                                style: TextStyle(color: Colors.white),
                              ),
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
