import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/folder_create.dart';
import 'package:flutter_application_1/api/sorting_rollback_service.dart';
import 'package:flutter_application_1/screens/show_filemove_dialog.dart';
import 'package:flutter_application_1/api/sorting_history_service.dart';

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
                                onTap: () async {
                                  print('텍스트 버튼 클릭됨');
                                  final histories =
                                      await SortingHistoryService.fetchSortingHistory(
                                        48,
                                      ); // 예시 sortingId

                                  if (histories.isNotEmpty) {
                                    final fromPath =
                                        histories.first['previousPath'] ?? '';
                                    final toPath =
                                        histories.first['currentPath'] ?? '';
                                    final fileName =
                                        histories.first['fileName'] ?? '';
                                    showFileMoveDialog(
                                      context,
                                      fromPath,
                                      toPath,
                                      fileName,
                                    );
                                  }
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
                            SizedBox(
                              height: 130, // 40(height) * 3 + 여백 약간
                              child: ListView.builder(
                                itemCount: pastDates.length,
                                itemBuilder: (context, index) {
                                  final date = pastDates[index];
                                  return Padding(
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFECECEC),
                                      ),
                                      child: Text(
                                        formatDate(date),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    //const SizedBox(height: 10),
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
