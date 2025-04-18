import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileSortyScreen extends StatefulWidget {
  final List<FileItem> files;
  final String username;
  final int sourceFolderId;
  final int destinationFolderId;

  const FileSortyScreen({
    super.key,
    required this.files,
    required this.username,
    required this.sourceFolderId,
    required this.destinationFolderId,
  });

  @override
  State<FileSortyScreen> createState() => _FileSortyScreenState();
}

class _FileSortyScreenState extends State<FileSortyScreen> {
  String? selectedMode;
  late String url;

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
      padding: const EdgeInsets.all(20),
      width: 800,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 영역
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF45525B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '파일 분류를 시작합니다 !',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 본문 영역: 왼쪽 선택된 파일 / 오른쪽 정리 설정
          Expanded(
            child: Row(
              children: [
                // 왼쪽: 선택된 파일 리스트
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: widget.files.length,
                      itemBuilder: (context, index) {
                        final file = widget.files[index];
                        return ListTile(
                          title: Text(file.name),
                          subtitle: Text(file.type),
                          leading: const Icon(Icons.insert_drive_file),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // 오른쪽: 기준 선택 + 정리 버튼
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('정리 기준을 선택해 주세요!', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // +버튼 (폴더 추가용)
                          IconButton(
                            onPressed: () {
                              // TODO: 폴더 추가 기능
                              print("폴더 추가!");
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 30,
                          ),

                          // 정리하기 버튼
                          ElevatedButton.icon(
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
                                  const SnackBar(content: Text('정렬 기준을 선택해 주세요.')),
                                );
                                return;
                              }

                              final response = await http.post(
                                Uri.parse('$url/organize/start'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  "folderId": widget.sourceFolderId,
                                  "mode": selectedMode,
                                  "destinationFolderId": widget.destinationFolderId,
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
                            label: const Text(
                              '정리하기',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
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
