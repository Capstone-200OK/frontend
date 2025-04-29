//최근항목 되돌리기 스크린린
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/sorting_rollback_service.dart';
import 'package:flutter_application_1/screens/show_filemove_dialog.dart';
import 'package:flutter_application_1/api/sorting_history_service.dart';

class RecentFileScreen extends StatefulWidget {
  final String username;
  final userId;

  const RecentFileScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<RecentFileScreen> createState() => _RecentFileScreenState();
}

class _RecentFileScreenState extends State<RecentFileScreen> {
  int? latestSortingId;
  DateTime? latestDate;
  List<DateTime> historyDates = [];
  bool isLoading = true;
  // 폴더 목록 상태 관리
  List<String> folders = [];
  bool _isHovering = false; // 마우스 호버 상태 정의
  List<Map<String, String>> sortingHistories = [];

  @override
  void initState() {
    super.initState();
    fetchSortyHistory(); // 2️⃣. initState에서 호출
  }

 Future<void> fetchSortyHistory() async {
  try {
    // (1) userId는 로그인 정보에서 받아야 함. 일단 임시 1
    final userId = 1; // 실제로는 Provider 같은 데서 받아와야 함

    // (2) 가장 최근 sortingId 가져오기
    latestSortingId = await SortingHistoryService.fetchLatestSortingHistoryId(userId);

    if (latestSortingId != null) {
      print('✅ 최신 sortingId: $latestSortingId');

      // (3) 최신 sortingId로 정리 기록 가져오기
      final histories = await SortingHistoryService.fetchSortingHistory(latestSortingId!);

      // (4) 여기서 날짜 계산도 실제 API 응답 기반으로
      final mockDates = [
        DateTime(2025, 4, 20, 12, 1),
        DateTime(2025, 4, 21, 15, 30),
        DateTime(2025, 4, 22, 9, 15),
        DateTime(2025, 4, 23, 18, 45),
      ]; // 지금은 mock인데 histories 안에 createdAt 같은 거 있으면 그걸 써

      setState(() {
        historyDates = mockDates;
        latestDate = mockDates.last;
        isLoading = false;
      });
    } else {
      print('❌ 최신 sortingId 가져오기 실패');
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    print('에러 발생: $e');
    setState(() {
      isLoading = false;
    });
  }
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

          title: Container(
            padding: const EdgeInsets.only(left: 80, top: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                      fontSize: 20,
                      fontFamily: 'APPLESDGOTHICNEOEB',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const SizedBox(height: 80),
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
                                        latestSortingId!,
                                      ); // 예시 ID

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
                                      allHistories: histories, // 전체 이력 넘겨줌
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
                                        latestSortingId!,
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
                              fontSize: 14,

                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            //과거 날짜 정리 기록
                            SizedBox(
                              height: 130,
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
                                      child: TextButton(
                                        onPressed: () {
                                          print('날짜 ${formatDate(date)} 클릭됨!');
                                          // TODO: 여기다가 클릭했을 때 원하는 기능 추가하면 됨
                                          // 예를 들면: 해당 날짜에 맞는 sorting 기록 보기 등
                                        },
                                        style: TextButton.styleFrom(
                                          padding:
                                              EdgeInsets.zero, // 텍스트 주변에 여백 제거
                                          alignment:
                                              Alignment.centerLeft, // 왼쪽 정렬
                                        ),
                                        child: Text(
                                          formatDate(date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'APPLESDGOTHICNEOR',
                                            color: Colors.black, // 버튼 안 텍스트 색
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24), // 간격
                          ],
                        ),
                      ),
                    ),

                    // 검색창
                    Align(
                      alignment: Alignment.center, // 센터 정렬
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 65,
                        ), // 🔹 위로 40만큼 띄움
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
