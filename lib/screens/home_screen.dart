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
        title: const Text(
          'SORTY FILE', // AppBar에 표시할 제목
          style: TextStyle(fontSize: 15), // 제목 글씨 크기 설정
        ),
        backgroundColor: Colors.white, // AppBar 배경색을 흰색으로 설정
      ),

      
      drawer: Drawer(
        child: ListView(
            padding: EdgeInsets.zero,
            children: [
                UserAccountsDrawerHeader(
                    accountName: Text(
                        username,
                        style: TextStyle(fontSize: 18, color: Colors.black),     
                    ),
                    accountEmail: Text(
                        '$username@example.com',
                        style: TextStyle(color: Colors.black), 
                    ),
                    decoration: BoxDecoration(color: Colors.grey[400]), 
                    currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.black),
                    ),    
                ),
                ListTile(
                    leading: Icon(Icons.home),
                    title: Text('홈'),
                     tileColor: Colors.white,
                    onTap: () => Navigator.pop(context),
                ),
                ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('설정'),
                    tileColor: Colors.white,
                    onTap: () => Navigator.pop(context),
                ),
                ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('로그아웃'),
                    tileColor: Colors.white,
                 onTap: () => Navigator.pop(context),
                ),
            ],
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
                  fontSize: 20, // 글씨 크기 설정
                  fontWeight: FontWeight.bold, // 글씨 두께 설정
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
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Column( // 아이콘 아래에 텍스트 배치
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 50, color: Colors.black), // 아이콘 삽입
                      SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                      Text('개인', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 15), // 버튼들 간의 간격 설정

                // 홈 버튼
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(200, 100),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, size: 50, color: Colors.black), 
                      SizedBox(width: 8),
                      Text('홈', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 15), // 버튼들 간의 간격 설정

                // 클라우드 버튼
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(200, 100),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud, size: 50, color: Colors.black), 
                      SizedBox(width: 8),
                      Text('클라우드', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 180),  // 요소 간의 간격 설정

            // 검색창(TextField) 부분
            TextField(
              decoration: InputDecoration(
                hintText: '검색', // 검색창의 힌트 텍스트
                border: OutlineInputBorder(), // 검색창의 테두리 설정
                suffixIcon: Icon(Icons.search, color: Colors.black), // 검색 아이콘을 오른쪽에 추가
              ),
            ),
            const SizedBox(height: 20), // 검색창과 다음 요소 간의 간격 설정

            // 아이디 및 개인정보 표시
            Row(
              children: [
                const Text(
                  '아이디: ', // 아이디 라벨 텍스트
                  style: TextStyle(color: Colors.black), // 라벨 텍스트 색상 설정
                ),
                Text(
                  username, // 전달받은 사용자 아이디를 표시
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // 아이디 글씨 스타일
                ),
              ],
            ),
            // 추가적인 개인정보는 여기에 추가하면 됩니다.
          ],
        ),
      ),
    );
  }
}