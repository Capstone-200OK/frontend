import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/sign_up_screen.dart'; // 회원가입 화면 불러오기
import 'package:http/http.dart' as http;
import 'dart:convert';

// 사용자 정보를 담을 클래스
class User {
  final String id; // 사용자 아이디
  final String email; // 사용자 이메일
  final String password; // 사용자 비밀번호

  // 생성자를 통한 사용자 정보 초기화
  User({required this.id, required this.email, required this.password});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 입력 필드에 사용할 컨트롤러
  final TextEditingController _idController =
      TextEditingController(); // 아이디 입력 컨트롤러
  final TextEditingController _emailController =
      TextEditingController(); // 이메일 입력 컨트롤러
  final TextEditingController _passwordController =
      TextEditingController(); // 비밀번호 입력 컨트롤러

  // 사용자 정보 리스트 (로그인할 때 비교할 데이터)
  List<User> users = [
    User(id: 'yeeun123', email: 'yeeun@naver.com', password: '123456'),
    User(id: '111111', email: '111@naver.com', password: '111111'),
    User(id: 'testUser', email: 'test@example.com', password: 'password123'),
  ];

  // 로그인 처리 함수
  void _login() async {
    // 텍스트 필드에서 입력된 값 가져오기
    // String id = _idController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    
    final url = Uri.parse("http://223.194.131.145:8080/user/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );
      print(response);
      if (response.statusCode == 200 && json.decode(response.body) == true) {
        // 로그인 성공
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: email), // 아이디 대신 이메일
          ),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인 성공')));
      } else {
        // 로그인 실패
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: 이메일 또는 비밀번호가 일치하지 않습니다.')),
        );
      }
    } catch (e) {
      // 서버 연결 실패 등
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF263238), // 화면 배경 색상 어두운 색
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 210, // AppBar 높이 늘려서

        title: Image.asset(
          'assets/images/LOGO-text2.png', // 이미지 경로
          height: 400, // 이미지 크기 조정
        ),
        backgroundColor: const Color(0xFF263238), //백그라운 컬러러
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 280.0,
          vertical: 10,
        ), // 위젯, 화면 사이 여백
        child: ListView(
          children: [
            // 아이디 입력 필드
            TextFormField(
              controller: _idController, // 아이디 입력을 위한 컨트롤러 연결
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: '아이디', // 필드 라벨 텍스트
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                border: OutlineInputBorder(), // 테두리 설정
              ),
            ),
            const SizedBox(height: 13), // 입력 필드 간 간격 설정
            // 이메일 입력 필드
            TextFormField(
              controller: _emailController, // 이메일 입력을 위한 컨트롤러 연결
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: '이메일', // 필드 라벨 텍스트
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                border: OutlineInputBorder(), // 테두리 설정
              ),
              keyboardType: TextInputType.emailAddress, // 이메일 형식 키보드 타입 설정
            ),
            const SizedBox(height: 13), // 입력 필드 간 간격 설정
            // 비밀번호 입력 필드
            TextFormField(
              controller: _passwordController, // 비밀번호 입력을 위한 컨트롤러 연결
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: '비밀번호', // 필드 라벨 텍스트
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                border: OutlineInputBorder(), // 테두리 설정
              ),
              obscureText: true, // 비밀번호는 가려서 표시
            ),
            const SizedBox(height: 13), // 입력 필드 간 간격 설정
            // 로그인 버튼
            ElevatedButton(
              onPressed: _login, // 로그인 버튼 클릭 시 _login 함수 호출
              child: const Text('로그인'), // 버튼 텍스트
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.grey[300],
                ), // 연한 회색 배경
                foregroundColor: MaterialStateProperty.all(
                  Colors.black,
                ), // 버튼 글자 색상 검정색
              ),
            ),
            const SizedBox(height: 20), // 버튼 간 간격 설정
            // 회원가입 화면으로 이동하는 버튼
            TextButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ), // 회원가입 화면으로 전환
                );
              },
              child: const Text(
                '회원가입',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 12,
                  decoration: TextDecoration.underline, // 밑줄 추가해서 클릭 가능한 느낌
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
