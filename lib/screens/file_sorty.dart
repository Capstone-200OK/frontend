import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/screens/show_loading_dialog.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

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
  late int? userId;
  bool isMaintain = false;
  bool isFileNameChange = false;
  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
    userId = Provider.of<UserProvider>(context, listen: false).userId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
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
                      ),

                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft, // 왼쪽 위 정렬
                            child: const Text(
                              '선택된 폴더',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'APPLESDGOTHICNEOEB',
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
                          IconButton(
                            onPressed: () {
                              print("폴더 추가!");
                            },
                            icon: const Icon(Icons.create_new_folder),
                            iconSize: 30,
                          ),
                          const SizedBox(height: 10),
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
                              fontSize: 16,
                              fontFamily: 'APPLESDGOTHICNEOEB',
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

                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedDestinationFolder?.name ??
                                        "폴더를 선택해주세요",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'APPLESDGOTHICNEOR',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.folder_open),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                '기존 폴더 유지',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'APPLESDGOTHICNEOEB',
                                ),
                              ),
                              Transform.scale(
                                scale: 0.7, // 🔸 0.8 = 80% 크기로 축소
                                child: Checkbox(
                                  value: isMaintain ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      isMaintain = value ?? false;
                                    });
                                  },
                                ),
                              ),
                                  if (selectedMode == 'content') ...[
                                    const SizedBox(width: 12),
                                    const Text(
                                      '기존 파일이름 유지',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'APPLESDGOTHICNEOEB',
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.7,
                                      child: Checkbox(
                                        value: isFileNameChange,
                                        onChanged: (value) {
                                          setState(() {
                                            isFileNameChange = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          const Spacer(),

                          // ③ 정리하기 버튼
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E24E0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 22,
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
                                showLoadingDialog(context); //로딩바

                                final response = await http.post( //정리요청
                                  Uri.parse('$url/organize/start'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    "folderIds": widget.sourceFolderIds,
                                    "mode": selectedMode,
                                    "destinationFolderId":
                                        selectedDestinationFolder!.id,
                                    "userId": userId,
                                    "isMaintain": isMaintain,
                                    "fileNameChange": isFileNameChange,
                                  }),
                                );
                                 Navigator.of(context, rootNavigator: true).pop(); 

                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('자동 정리가 완료되었습니다.'),
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
                                Icons.cleaning_services,
                                color: Colors.white,
                              ),
                              label: const Text(
                                '정리하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'APPLESDGOTHICNEOEB',
                                ),
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
        backgroundColor:
            selectedMode == mode ? Color(0xFF37474F) : Colors.white,
        foregroundColor:
            selectedMode == mode ? Colors.white : Color(0xFF37474F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          selectedMode = mode;
        });
      },
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontFamily: 'APPLESDGOTHICNEOR'),
      ),
    );
  }
}
