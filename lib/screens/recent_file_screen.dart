import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/api/sorting_rollback_service.dart';

class RecentFileScreen extends StatefulWidget {
  final String username;

  const RecentFileScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<RecentFileScreen> createState() => _RecentFileScreenState();
}

class _RecentFileScreenState extends State<RecentFileScreen> {
  DateTime? latestDate;
  List<DateTime> historyDates = [];
  bool isLoading = true;
  // 폴더 목록 상태 관리
  List<String> folders = [];
  bool _isHovering = false; // 마우스 호버 상태 정의

  @override
  void initState() {
    super.initState();
    fetchSortyHistory();
  }

  Future<void> fetchSortyHistory() async {
    // 🔁 예시: 실제 API 호출로 바꿔야 함
    await Future.delayed(const Duration(milliseconds: 800)); // mock delay

    // 예시 response -> 실제 API 결과로 치환 필요
    final mockDates = [
      DateTime(2025, 4, 20, 12, 1),
      DateTime(2025, 4, 20, 12, 1),
      DateTime(2025, 4, 20, 12, 1),
      DateTime(2025, 4, 20, 12, 1),
      DateTime(2025, 4, 23),
    ];

    setState(() {
      historyDates = mockDates;
      latestDate = mockDates.last;
      isLoading = false;
    });
  }

  String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final pastDates = historyDates.where((d) => d != latestDate).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
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
              Expanded(
                child: Text(
                  "${widget.username}님의 SORTY 기록",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    //fontWeight: FontWeight.bold,
                    fontFamily: 'APPLESDGOTHICNEOEB',
                  ),
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
                onTap: () async {
                  // 짧은 딜레이 후 팝업 표시 ( 드로어 닫힘 타이밍 맞추기 )
                  await Future.delayed(const Duration(milliseconds: 100));

                  final RenderBox overlay =
                      Overlay.of(context).context.findRenderObject()
                          as RenderBox;
                  final RelativeRect position = RelativeRect.fromLTRB(
                    100, // 좌측에서 거리
                    210, // 위에서 거리
                    overlay.size.width - 100,
                    0,
                  );
                  final selected = await showMenu<String>(
                    context: context,
                    position: position,
                    items: [
                      const PopupMenuItem(
                        value: 'new_folder',
                        child: Text('새 폴더'),
                      ),
                      const PopupMenuItem(
                        value: 'upload_file',
                        child: Text('파일 업로드'),
                      ),
                      const PopupMenuItem(
                        value: 'upload_folder',
                        child: Text('폴더 업로드'),
                      ),
                    ],
                  ).then((selected) async {
                    // folder_create를 불러와서 폴더 생성하는 팝업창
                    if (selected == 'new_folder') {
                      final result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Container(
                              width: 300, // 너비 설정
                              height: 280, // 높이 설정
                              child: FolderCreateScreen(
                                onCreateFolder: (folderName) {
                                  setState(() {
                                    folders.add(folderName);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ), // 실제 내용
                            ),
                          );
                        },
                      );
                      if (result == true) {
                        print('새 폴더 생성 완료');
                      }
                    }
                    // 다른 항목은 여기에 맞게 처리
                  });
                },
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
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 105.0),
                      child: Container(
                        height: 170, //박스 높이
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF263238),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 100,
                            ),
                            const SizedBox(width: 60),

                            MouseRegion(
                              onEnter:
                                  (_) => setState(() => _isHovering = true),
                              onExit:
                                  (_) => setState(() => _isHovering = false),
                              child: GestureDetector(
                                onTap: () {
                                  print('텍스트 버튼 클릭됨');
                                  // 여기에 원하는 동작 넣기
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    Text(
                                      "The most up to date",
                                      style: TextStyle(
                                        color:
                                            _isHovering
                                                ? const Color(0xFFFDE155)
                                                : Colors.white,
                                        fontSize: 25,
                                        fontFamily: 'APPLESDGOTHICNEOR',
                                      ),
                                    ),
                                    Text(
                                      "${latestDate?.year}.${latestDate?.month.toString().padLeft(2, '0')}.${latestDate?.day.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        color:
                                            _isHovering
                                                ? const Color(0xFFFDE155)
                                                : Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),
                            Container(
                              height: 80, //높이
                              width: 80, //너비
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: InkWell(
                                onTap: () async {
                                  print('UNDO 클릭됨!');

                                  final success =
                                      await SortingRollbackService.rollbackSorting(
                                        45,
                                      ); // 임시 sortingId = 45

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("자동 분류를 되돌렸습니다!"),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("되돌리기 실패 😢"),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  children: const [
                                    const SizedBox(height: 5),
                                    Icon(
                                      Icons.undo,
                                      color: Colors.black,
                                      size: 43,
                                    ),
                                    Text(
                                      "undo",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 110.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
                        children: const [
                          Text(
                            "과거 정리 기억",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'APPLESDGOTHICNEOR',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ...pastDates.map(
                              (date) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 105.0,
                                  vertical: 3,
                                ),
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECECEC),
                                  ),
                                  child: Text(
                                    formatDate(date),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
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
                            hintText: '날짜를 입력해보세요', // 검색창의 힌트 텍스트
                            hintStyle: TextStyle(
                              fontSize: 14, // 힌트 텍스트 크기
                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
                            filled: true, // 🔹 배경색 적용할 때 필수
                            fillColor: Color(0xFFCFD8DC), //  TextField 배경색
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                15,
                              ), // 둥근 정도 설정
                              borderSide:
                                  BorderSide.none, // 기본 테두리 제거 (filled일 때 깔끔)
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
