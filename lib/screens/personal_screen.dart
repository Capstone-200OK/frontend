import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'file_uploader.dart';
import 'package:flutter_application_1/screens/file_sorty.dart';


class PersonalScreen extends StatefulWidget {
  final String username;

  const PersonalScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  // 파일 선택 상태 저장용 리스트
  List<FileItem> selectedFiles = [];
  Set<String> fileNames = {}; // 중복 방지를 위한 파일 이름 저장용 집합


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false, // 기본 뒤로가기/햄버거 제거
          backgroundColor: Colors.white,
          elevation: 0,

          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
          ),
          title: Row(
            children: [
              const SizedBox(width: 10), //햄버거 버튼과의 간격
              // 뒤로가기 버튼
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff263238),
                  size: 15,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),

              // 타이틀
              Expanded(
                child: Text(
                  '${widget.username}님의 파일함',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //아이콘 버튼
              Padding(
                padding: const EdgeInsets.only(right: 34), // 오른쪽에서 10px 떨어짐
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xff263238),
                      ), // 환경설정 아이콘
                      onPressed: () {
                        // 환경설정 페이지 이동 로직
                        print('환경설정 눌림');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xff263238),
                      ), //최근항목아이콘
                      onPressed: () {
                        // 최근 항목 페이지 이동 로직
                        print('최근 항목 눌림');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Color(0xff263238),
                      ), //d알림 버튼튼
                      onPressed: () {
                        print('알림 눌림');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 모서리 각지게
        ),
        child: Container(
          color: Color(0xFF455A64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Color(0xFF455A64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18, // 원 크기
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: Color(0xFF455A64),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'APPLESDGOTHICNEOEB',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.username}@example.com',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 70), //사이 간격
              ListTile(
                leading: Icon(
                  Icons.file_upload,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '업로드',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.star_border,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '중요문서함',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '휴지통',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon( 
                  Icons.check,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '예약하기',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.sd_storage,
                  size: 24, // 아이콘 크기 (기본값: 24)
                  color: Colors.white,
                ),
                title: Text(
                  '저장용량',
                  style: TextStyle(
                    fontSize: 12, // 글씨 크기
                    color: Colors.white, // 글씨 색
                    fontFamily: 'APPLESDGOTHICNEOR', // 원하는 폰트 사용 가능
                  ),
                ),
                tileColor: Color(0xFF455A64),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 폴더 & 파일 레이블
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 80.0), // ← 원하는 만큼 조절
                    child: Text(
                      '폴더',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 110.0),
                    child: Text(
                      '파일',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'APPLESDGOTHICNEOR',
                      ),
                    ),
                  ),
                ),

                Padding(
                    padding: const EdgeInsets.only(right: 100),
                    child: ElevatedButton(
                        onPressed: () {
                            // 선택한 파일 정렬
                            selectedFiles.sort((a, b) => a.name.compareTo(b.name));
                            // file_sorty.dart로 이동하면서 selectedFiles 전달
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FileSortyScreen(
                                        files: selectedFiles,
                                        username: widget.username, 
                                    ),
                                ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 6,
                            ),
                        ),
                        child: const Text(
                            'SORTY',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
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
                      height: 425,
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
                          vertical: 12,
                          horizontal: 7,
                        ),

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

                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0.1,
                                    ),

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
                                                Color
                                              >((states) {
                                                if (states.contains(
                                                  MaterialState.disabled,
                                                )) {
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
                                                  file.name.length > 10
                                                      ? '${file.name.substring(0, 10)}...'
                                                      : file.name,

                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'APPLESDGOTHICNEOR',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,

                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${file.type} / ${file.sizeFormatted}',
                                                  style: TextStyle(fontSize: 8),
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
                                                      fileNames.remove(
                                                        file.name,
                                                      );
                                                      selectedFiles.removeAt(
                                                        index,
                                                      );
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
            const SizedBox(height: 5),

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
