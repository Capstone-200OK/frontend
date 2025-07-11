import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/folder_select_dialog.dart';
import 'package:flutter_application_1/screens/show_loading_dialog.dart';
import 'package:flutter_application_1/models/folder_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

// 자동 정리 화면 클래스 - 사용자가 선택한 폴더들을 정리할 수 있는 화면
class FileSortyScreen extends StatefulWidget {
  final List<FolderItem> folders; // 정리 대상이 되는 폴더 목록
  final String username; // 현재 로그인한 사용자 이름
  final List<int> sourceFolderIds; // 정리 대상이 되는 폴더들의 ID목록
  final int destinationFolderId; // 정리 결과가 저장될 목적지 폴더의 ID

  // 생성자 - 필수 값들을 파라미터로 받음
  const FileSortyScreen({
    super.key,
    required this.folders, // 폴더 리스트 받기
    required this.username,
    required this.sourceFolderIds,
    required this.destinationFolderId,
  });

  @override
  State<FileSortyScreen> createState() => _FileSortyScreenState(); // State 객체 생성
}

// FileSortyScreen의 상태 클래스 - 자동 정리 로직 및 UI 처리
class _FileSortyScreenState extends State<FileSortyScreen> {
  String? selectedMode; // 선택된 정리 기준
  late String url; // 서버 URL
  FolderItem? selectedDestinationFolder; // 선택된 목적지 폴더
  late int? userId; // 사용자 ID
  bool isMaintain = false; // 기존 폴더 유지 여부
  bool isFileNameChange = false; // 파일 이름 유지 여부 ( 내용 기준일 경우만 )
  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl"); // .env에서 BaseUrl 가져오기
    userId = Provider.of<UserProvider>(context, listen: false).userId; // Provider 통해 userId 가져오기
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
            // 상단 타이틀 영역
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

            // 좌우 화면 분할 영역
            SizedBox(
              height: 400,
              child: Row(
                children: [
                  // 선택 폴더 목록 ( 왼쪽 )
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
                          const Text(
                            '목적지 폴더',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 폴더 선택 영역
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

                          // 정리 기준 선택
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

                          // 옵션 체크박스
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
                                scale: 0.7, 
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

                            // 정리하기 버튼
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
                                showLoadingDialog(context); //로딩 다이얼로그 표시

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
                                 Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기

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

  // 정리 기준 버튼 위젯
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