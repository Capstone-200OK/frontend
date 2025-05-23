//최근항목 되돌리기 스크린린
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/sorting_rollback_service.dart';
import 'package:flutter_application_1/screens/show_filemove_dialog.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/api/sorting_history_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

// 최근 정리된 파일 목록을 보여주는 화면 (SORTY 기록 화면)
class RecentFileScreen extends StatefulWidget {
  final String username; // 사용자 이름
  final userId; // 사용자 ID

  // 생성자: 사용자 이름과 ID를 필수로 받음
  const RecentFileScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<RecentFileScreen> createState() => _RecentFileScreenState();
}

class _RecentFileScreenState extends State<RecentFileScreen> {
  int? latestSortingId; // 가장 최근 정리 기록의 ID
  DateTime? latestDate;  // 가장 최근 정리 날짜
  List<DateTime> historyDates = []; // 전체 정리 날짜 리스트
  bool isExist = true; // 기록 존재 여부
  bool isLoading = true; // 로딩 중 여부
  List<String> folders = []; // 폴더 목록 상태 관리
  bool _isHovering = false; // 마우스 호버 상태 정의
  List<Map<String, String>> sortingHistories = []; // 정리 기록 상세 정보
  late int? userId; // 사용자 ID
  late String url; // API 호출을 위한 Base URL
  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl"); // .env에서 base URL 가져오기
    // buildContext가 유효해진 후 userId를 가져와서 기록 조회 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        userId = Provider.of<UserProvider>(context, listen: false).userId;
        fetchSortyHistory(); // 정리 기록 가져오기
      });
    });
  }

  // 최근 정리 기록 데이터 불러오기
  Future<void> fetchSortyHistory() async {
    try {
      // (1) 가장 최신 정리 기록 ID 요청
      latestSortingId = await SortingHistoryService.fetchLatestSortingHistoryId(
        userId!,
      );

      // 기록이 없다면 종료
      if (latestSortingId == null) {
        setState(() {
          isExist = true;
          isLoading = false;
        });
        return;
      }

      // (2) 가장 최근 정리 기록 상세 내역 요청
      final histories = await SortingHistoryService.fetchSortingHistory(latestSortingId!, userId!);

      // (3) 전체 날짜 목록 요청
      final response = await http.get(
        Uri.parse('$url/sorting-history/list/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // 날짜 목록 파싱
        List<DateTime> fetchedDates = data
            .map((entry) => DateTime.parse(entry['sortingDate']))
            .toList();

        setState(() {
          historyDates = fetchedDates;
          latestDate = fetchedDates.isNotEmpty ? fetchedDates.first : null;
          isLoading = false;
          isExist = fetchedDates.isEmpty;
        });
      } else {
        print('❌ 정리 기록 가져오기 실패');
        setState(() {
          isExist = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 에러 발생: $e');
      setState(() {
        isExist = true;
        isLoading = false;
      });
    }
  }

  // 날짜를 보기 좋은 포맷으로 변환
  String formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // 가장 최근 날짜를 제외한 과거 기록 목록
    final pastDates = historyDates.where((d) => d != latestDate).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // 상단 앱바 정의
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,  // 기본 뒤로가기 제거
          backgroundColor: Colors.white,

          title: Container(
            padding: const EdgeInsets.only(left: 80, top: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 홈 버튼
                IconButton(
                  icon: const Icon(Icons.home, color: Color(0xff263238)),
                  onPressed: () {
                    NavigationStack.clear(); // 내비게이션 스택 초기화
                    NavigationStack.push('HomeScreen', arguments: {'username': widget.username});
                    NavigationStack.printStack();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HomeScreen(username: widget.username),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 22),

                // 뒤로가기 버튼
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xff263238),
                    size: 15,
                  ),
                  onPressed: () => NavigationHelper.navigateToPrevious(context),
                ),
                const SizedBox(width: 8),

                // 화면 제목
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
        child: isLoading
          // 로딩 중일 때는 로딩 인디케이터 표시
          ? const Center(child: CircularProgressIndicator()) // 🔹 무조건 먼저 보여줌
            : isExist
                // 정리 기록이 존재하지 않을 경우 안내 메시지 표시
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 150,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, 
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "아직 정리된 기록이 없습니다.",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'APPLESDGOTHICNEOEB',
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "파일을 정리하고 기록을 확인해보세요!",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'APPLESDGOTHICNEOR',
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : isLoading
                ? const Center(child: CircularProgressIndicator())
                // 기록이 존재할 경우 최근 기록 박스를 표시
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
                            // 시계 아이콘
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 100,
                            ),
                            const SizedBox(width: 60),

                            // 마우스 호버 감지 및 클릭 시 기록 상세 보기
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
                                        latestSortingId!,userId!,
                                      ); // 예시 ID

                                  if (histories.isNotEmpty) {
                                    final fromPath =
                                        histories.first['previousPath'] ?? '';
                                    final toPath =
                                        histories.first['currentPath'] ?? '';
                                    final fileName =
                                        histories.first['fileName'] ?? '';

                                    // 정리된 파일의 경로 및 이름을 보여주는 다이얼로그 호출
                                    showFileMoveDialog(
                                      context,
                                      fromPath,
                                      toPath,
                                      fileName,
                                      allHistories: histories,
                                    );
                                  } else {
                                    print('❌ 정리 내역 없음');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('파일 정리 내역이 없습니다.'),
                                      ),
                                    );
                                  }
                                },

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    // 정리 기록 타이틀
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
                                    // 날짜 출력
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

                            // undo 버튼 (되돌리기 기능)
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
                                      ); 

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
                    const SizedBox(height: 24), // 아래 여백
                    
                    // 과거 정리 기록 텍스트
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 110.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
                        children: const [
                          Text(
                            "과거 정리 기억", // 섹션 제목
                            style: TextStyle(
                              fontSize: 14,

                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5), // 제목과 리스트 사이 간격

                    // 과거 기록 리스트 (스크롤 가능)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            
                            // 과거 날짜별 정리 기록을 보여주는 리스트
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

                                      // 날짜 버튼 (정리 기록 확인용)
                                      child: TextButton(
                                        onPressed: () async {
                                          print('날짜 ${formatDate(date)} 클릭됨!');

                                          try {
                                            if (userId == null) return;
                                            // 선택한 날짜의 sortingId 가져오기
                                            final sortingId = await SortingHistoryService.fetchSortingIdByDate(
                                                  userId!,
                                                  date,
                                                );
                                            if (sortingId == null) return;
                                            // 해당 sortingId의 파일 이동 기록 가져오기
                                            final histories = await SortingHistoryService.fetchSortingHistory(sortingId, userId!);

                                            // 기록이 존재하면 다이얼로그로 표시
                                            if (histories.isNotEmpty) {
                                              final fromPath =
                                                  histories
                                                      .first['previousPath'] ??
                                                  '';
                                              final toPath =
                                                  histories
                                                      .first['currentPath'] ??
                                                  '';
                                              final fileName =
                                                  histories.first['fileName'] ??
                                                  '';

                                              showFileMoveDialog(
                                                context,
                                                fromPath,
                                                toPath,
                                                fileName,
                                                allHistories: histories,
                                              );
                                            } else {
                                              print('❌ 정리 내역 없음');
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '파일 정리 내역이 없습니다.',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print('❌ 정리 이력 불러오기 실패: $e');
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '정리 기록을 불러오지 못했습니다.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          padding:
                                              EdgeInsets.zero, // 텍스트 주변 여백 제거
                                          alignment:
                                              Alignment.centerLeft, // 텍스트 왼쪽 정렬
                                        ),
                                        child: Text(
                                          formatDate(date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'APPLESDGOTHICNEOR',
                                            color: Colors.black, 
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24), // 리스트와 다음 요소 간 간격
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
                              filled: true, // 배경색 적용할 때 필수
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
