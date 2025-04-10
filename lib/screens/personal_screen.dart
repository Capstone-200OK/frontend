import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';

// 파일 정보 클래스
class FileItem {
  final String name;
  final String type;
  final int sizeInBytes;
  bool isSelected;

  FileItem({
    required this.name,
    required this.type,
    required this.sizeInBytes,
    this.isSelected = false,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '${sizeInBytes}B';
    return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
  }
}

class PersonalScreen extends StatefulWidget {
  final String username;

  const PersonalScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // 파일 선택 상태 저장용 리스트
  List<FileItem> selectedFiles = [];
  Set<String> fileNames = {}; // 🔹 중복 방지를 위한 파일 이름 저장용 집합

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.username}님의 파일함',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF263238)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const Icon(Icons.history, color: Color(0xFF263238)),
          const SizedBox(width: 10),
          const Icon(Icons.settings, color: Color(0xFF263238)),
          const SizedBox(width: 10),
        ],
      ),
      drawer: const Drawer(), // 필요 시 구현
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 폴더 & 파일 레이블
            Row(
              children: [
                Expanded(
                  child: Text(
                    '폴더',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '파일',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'APPLESDGOTHICNEOR',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 파일 이름 기준으로 정렬
                    selectedFiles.sort((a, b) => a.name.compareTo(b.name));
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // ← 둥글기 없이
                    ),
                  ),
                  child: const Text(
                    'SORTY',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 폴더 & 파일 영역
            Container(
              height: 450,
              width: 800,
              child: Row(
                children: [
                  // 폴더 리스트
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFCFD8DC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        itemCount: 8,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.folder,
                                color: Color(0xFF263238),
                              ),
                              label: const Text(
                                '학생회',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'APPLESDGOTHICNEOR',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 파일 리스트
                  Expanded(
                    // DropTarget (파일 드래그 앤 드랍)
                    child: DropTarget(
                      onDragDone: (detail) {
                        for (final file in detail.files) {
                          final fileName = file.name;
                          if (!fileNames.contains(fileName)) {
                            final fileType = fileName.split('.').last;
                            final fileSize = File(file.path).lengthSync();
                            final fileItem = FileItem(
                              name: fileName,
                              type: fileType,
                              sizeInBytes: fileSize,
                            );
                            selectedFiles.add(fileItem);
                            fileNames.add(fileName);
                          }
                        }
                        setState(() {});
                      },
                      onDragEntered: (details) {
                        print('드래그 시작');
                      },
                      onDragExited: (details) {
                        print('드래그 종료');
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFECEFF1),
                          border: Border.all(color: Color(0xff90A4AE)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // 파일 리스트뷰
                            Expanded(
                              child: ListView.builder(
                                itemCount: selectedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = selectedFiles[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 0.1),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // 체크박스 (배경 외부에 위치)
                                        Checkbox(
                                          value: file.isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              file.isSelected = value ?? false;
                                            });
                                          },
                                          activeColor: Color(0xff263238),
                                          side: const BorderSide(
                                            color: Colors.white,
                                            width: 0.1,
                                          ),
                                          fillColor:
                                              MaterialStateProperty.resolveWith<
                                                  Color>((states) {
                                            if (states.contains(
                                                MaterialState.disabled)) {
                                              return Colors.white;
                                            }
                                            return Colors.white;
                                          }),
                                          checkColor: Color(0xff263238),
                                        ),

                                        // 나머지 내용 (하얀 배경 + 둥근 모서리)
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.description,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 8),
                                                
                                                Text(
                                                  file.name.length > 10 ? '${file.name.substring(0, 10)}...' : file.name, 
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'APPLESDGOTHICNEOR',
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${file.type} / ${file.sizeFormatted}',
                                                  style:
                                                      TextStyle(fontSize: 8),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.star_border,
                                                  size: 10,
                                                ),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      fileNames.remove(file.name);
                                                      selectedFiles.removeAt(index);
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 검색창
            Align(
              alignment: Alignment.center, // 센터 정렬
              child: SizedBox(
                width: 800, // 원하는 가로폭
                child: TextField(
                  style: TextStyle(
                    fontSize: 16, // 입력 텍스트 크기
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
                  decoration: InputDecoration(
                    hintText: 'search', // 검색창의 힌트 텍스트
                    hintStyle: TextStyle(
                      fontSize: 16, // 힌트 텍스트 크기
                      fontFamily: 'APPLESDGOTHICNEOEB',
                    ),
                    filled: true, // 🔹 배경색 적용할 때 필수
                    fillColor: Color(0xFFCFD8DC), //  TextField 배경색
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), // 둥근 정도 설정
                      borderSide: BorderSide.none, // 기본 테두리 제거 (filled일 때 깔끔)
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Color(0xFF607D8B),
                        width: 2,
                      ), // 포커스 시 진한 테두리
                    ),
                    //border: OutlineInputBorder(), // 검색창의 테두리 설정
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xff263238),
                      // 검색 아이콘을 왼쪽에 추가
                    ),
                    suffixIcon: Icon(
                      Icons.tune,
                      color: Color(0xff263238),
                    ), // 오른쪽 '조절' 아이콘
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
