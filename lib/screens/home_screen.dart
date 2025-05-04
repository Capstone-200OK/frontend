import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  // 생성자에 사용자 이름을 전달받음
  const HomeScreen({Key? key, required this.username}) : super(key: key);

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
                              username: username,
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
        username: username,
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
                '$username님, 안녕하세요', // 사용자 이름을 동적으로 출력
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
                            (context) => PersonalScreen(username: username, targetPathIds: null,),
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
                        builder: (context) => CloudScreen(username: username),
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
                    ), // 검색 아이콘을 왼쪽에에 추가
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
