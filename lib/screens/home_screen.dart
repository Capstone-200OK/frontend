import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.only(right: 50), // 오른쪽에서 10px 떨어짐
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

      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 🔸 모서리 각지게
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
                          username,
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
                      '$username@example.com',
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
                  onPressed: () {},
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
                const SizedBox(width: 50), // 버튼들 간의 간격 설정
                // 홈 버튼
                ElevatedButton(
                  onPressed: () {},
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
                      Icon(Icons.home, size: 50, color: Color(0xff263238)),
                      SizedBox(width: 8),
                      Text(
                        '홈',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'APPLESDGOTHICNEOEB',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 50), // 버튼들 간의 간격 설정
                // 클라우드 버튼
                ElevatedButton(
                  onPressed: () {},
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

            const SizedBox(height: 200), // 요소 간의 간격 설정
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
