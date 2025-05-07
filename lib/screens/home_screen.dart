import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';
import 'dart:convert'; // for jsonDecode
import 'package:http/http.dart' as http; // for http.get
import 'package:flutter_dotenv/flutter_dotenv.dart'; // for dotenv.get


class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  OverlayEntry? _searchOverlay;
  late int? userId;
  late String url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      url = dotenv.get("BaseUrl");
    });
  }

  Future<void> searchFoldersAndFiles(String input) async {
    if (input.trim().isEmpty || userId == null) return;

    final folderRes = await http.get(Uri.parse('$url/folder/search/$userId/$input'));
    final fileRes = await http.get(Uri.parse('$url/file/search/$userId/$input'));

    if (folderRes.statusCode == 200 && fileRes.statusCode == 200) {
      final folderJson = List<Map<String, dynamic>>.from(
        jsonDecode(folderRes.body).map((e) => Map<String, dynamic>.from(e)),
      );

      final fileJson = List<Map<String, dynamic>>.from(
        jsonDecode(fileRes.body).map((e) => Map<String, dynamic>.from(e)),
      );

      final combinedResults = [
        ...folderJson.map((e) => {...e, 'type': 'folder'}),
        ...fileJson.map((e) => {...e, 'type': 'file'}),
      ];

      showSearchOverlay(combinedResults);
    }
  }

  TextSpan highlightOccurrences(String source, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: source,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      );
    }

    final matches = <TextSpan>[];
    final lcSource = source.toLowerCase();
    final lcQuery = query.toLowerCase();

    int start = 0;
    int index = lcSource.indexOf(lcQuery, start);

    while (index != -1) {
      if (index > start) {
        matches.add(TextSpan(
          text: source.substring(start, index),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ));
      }

      matches.add(TextSpan(
        text: source.substring(index, index + query.length),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          fontSize: 14,
        ),
      ));

      start = index + query.length;
      index = lcSource.indexOf(lcQuery, start);
    }

    if (start < source.length) {
      matches.add(TextSpan(
        text: source.substring(start),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ));
    }

    return TextSpan(children: matches);
  }

  void showSearchOverlay(List<Map<String, dynamic>> results) {
    _removeSearchOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _searchOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 100,
        top: position.dy + 90,
        width: 800,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            child: ListView(
              shrinkWrap: true,
              children: results.map((item) {
                final isFolder = item['type'] == 'folder';
                return ListTile(
                  leading: Icon(
                    isFolder ? Icons.folder : Icons.insert_drive_file,
                    color: isFolder ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                  title: RichText(
                    text: highlightOccurrences(
                      item[isFolder ? 'folderName' : 'fileName'],
                      _searchController.text,
                    ),
                  ),
                  subtitle: Text(
                    item['parentFolderName'] != null
                        ? '${item['parentFolderName']}'
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () async {
                    if (isFolder) {
                      final folderId = item['folderId'];
                      final response = await http.get(Uri.parse('$url/folder/path/$folderId'));

                      if (response.statusCode == 200) {
                        final List<dynamic> jsonList = jsonDecode(response.body);
                        final List<int> pathIds = jsonList.map((e) => e['folderId'] as int).toList();

                        _removeSearchOverlay();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalScreen(
                              username: widget.username,
                              targetPathIds: pathIds,
                            ),
                          ),
                        );
                      }
                    } else {
                      final parentId = item['parentFolderId'];
                      final response = await http.get(Uri.parse('$url/folder/path/$parentId'));

                      if (response.statusCode == 200) {
                        final List<dynamic> jsonList = jsonDecode(response.body);
                        final List<int> pathIds = jsonList.map((e) => e['folderId'] as int).toList();

                        _removeSearchOverlay();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalScreen(
                              username: widget.username,
                              targetPathIds: pathIds,
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_searchOverlay!);
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 AppBar 설정
      appBar: AppBar(
        title: Image.asset(
          'assets/images/LOGO-text.png', //로고 이미지지
          height: 230, // 이미지 높이 조정
        ),
        //centerTitle: true, // 가운데 정렬 (선택사항)
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 111), // 오른쪽에서 10px 떨어짐
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.history,
                    color: Color(0xff263238),
                  ), //최근항목아이콘
                  onPressed: () {
                    final userId =
                        Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).userId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecentFileScreen(
                              username: widget.username,
                              userId: userId,
                            ),
                      ),
                    );
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

      drawer: NavigationDrawerWidget(
        username: widget.username,
        onFolderCreated: (folderName) {
          // 필요 시 폴더 생성 후 작업 추가
        },
        folders: const [], // 필요시 폴더 목록 전달
        scaffoldContext: context,
        showUploadButton: false,
      ),

      // 화면 내용 부분
      body: Container(
        color: Colors.white, // 전체 화면 배경색을 흰색으로 설정
        padding: const EdgeInsets.all(16.0), // 화면 가장자리 여백 설정
        child: Column(
          children: [
            Align(
              alignment: Alignment.center, // 글씨를 화면 중앙에 배치
              child: Text(
                '${widget.username}님, 안녕하세요', // 사용자 이름을 동적으로 출력
                style: const TextStyle(
                  fontSize: 30, // 글씨 크기 설정
                  fontFamily: 'APPLESDGOTHICNEOEB',
                  color: Colors.black, // 글씨 색상은 검정색
                ),
              ),
            ),
            const SizedBox(height: 100), // 요소 간의 간격 설정
            // 개인, 홈, 클라우드 버튼들이 가로로 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 버튼들을 화면 중앙에 배치
              children: [
                // 개인 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PersonalScreen(username: widget.username, targetPathIds: null,),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // 모서리를 둥글게
                    ),
                    minimumSize: const Size(200, 100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 30,
                    ),
                    backgroundColor: Color(0xFFCFD8DC), //아이콘 색색
                    foregroundColor: Colors.black,
                  ),
                  child: const Column(
                    // 아이콘 아래에 텍스트 배치
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xff263238),
                      ), // 아이콘 삽입
                      SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                      Text(
                        '개인',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'APPLESDGOTHICNEOEB',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 150), // 버튼들 간의 간격 설정
                // 클라우드 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CloudScreen(username: widget.username),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(200, 100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 30,
                    ),
                    backgroundColor: Color(0xFFCFD8DC),
                    foregroundColor: Colors.black,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud, size: 50, color: Color(0xff263238)),
                      SizedBox(width: 8),
                      Text(
                        '클라우드',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'APPLESDGOTHICNEOEB',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 237), // 요소 간의 간격 설정
            // 검색창(TextField) 부분
            Align(
              alignment: Alignment.center, // 센터 정렬
              child: SizedBox(
                width: 800, // 원하는 가로폭
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    searchFoldersAndFiles(value);
                  },
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
