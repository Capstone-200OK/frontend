import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_screen.dart'; // 로그인 화면 불러오기
import 'package:http/http.dart' as http; // HTTP 요청을 위한 패키지
import 'dart:convert'; // JSON 인코딩/디코딩
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 환경변수 사용을 위한 패키지

// 회원가입 화면 Stateful 위젯 정의
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // 폼 상태 관리용 키
  final _formKey = GlobalKey<FormState>();

  // 입력 필드를 위한 컨트롤러
  final TextEditingController _idController = TextEditingController(); // 아이디 입력 컨트롤러
  final TextEditingController _emailController = TextEditingController(); // 이메일 입력 컨트롤러
  final TextEditingController _passwordController = TextEditingController(); // 비밀번호 입력 컨트롤러
  String urlAddress = dotenv.get("BaseUrl"); // .env에서 API URL 읽기

  // 서버로 회원가입 요청을 보내는 함수
  Future<void> _registerUser() async {
    final String nickname = _idController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;


    // 스프링부트 회원가입 엔드포인트
    final url = Uri.parse('$urlAddress/user/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': nickname,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공 시 로그인 화면으로 이동
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원가입 성공')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // 실패 시 서버 응답 본문 출력
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('회원가입 실패: ${response.body}')));
      }
    } catch (e) {
      // 예외처리
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    }
  }

  // 아이디 유효성 검사
  String? _idValidator(String? value) {
    // 입력값이 비어있으면 오류 메시지 반환
    if (value == null || value.isEmpty) {
      return '아이디를 입력하세요.';
    }
    return null; // 유효한 아이디인 경우 null 반환
  }

  // 이메일 유효성 검사
  String? _emailValidator(String? value) {
    // 이메일이 비어있으면 오류 메시지 반환
    if (value == null || value.isEmpty) {
      return '이메일을 입력하세요.';
    }
    // 이메일 형식이 맞는지 정규식으로 확인
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return '유효한 이메일 주소를 입력하세요.';
    }
    return null; // 유효한 이메일 형식일 경우 null 반환
  }

  // 비밀번호 유효성 검사
  String? _passwordValidator(String? value) {
    // 비밀번호가 비어있으면 오류 메시지 반환
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력하세요.';
    }
    // 비밀번호 길이가 6자 미만이면 오류 메시지 반환
    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다.';
    }
    return null; // 유효한 비밀번호일 경우 null 반환
  }

  // 폼 제출 처리 함수
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_formKey.currentState!.validate()) {
        _registerUser(); // → 스프링부트로 회원가입 요청 보내기
      }
      // 폼 유효성 검사
      // 모든 필드가 유효하면 성공 메시지 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입 완료')));

      // 회원가입 후 로그인 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ), // 로그인 화면으로 전환
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 화면 배경 색상 흰색
      appBar: AppBar(
        title: const Text(
          '회원가입', // AppBar의 제목 텍스트
          style: TextStyle(fontSize: 15), // 제목 글씨 크기 설정
        ),
        backgroundColor: Colors.white, // AppBar 배경색을 흰색으로 설정
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 화면 여백 설정
        child: Form(
          key: _formKey, // 폼 키 설정
          child: ListView(
            children: [
              // 아이디 입력 필드
              TextFormField(
                controller: _idController, // 아이디 입력 컨트롤러 연결
                decoration: const InputDecoration(
                  labelText: '아이디', // 아이디 라벨 텍스트
                  border: OutlineInputBorder(), // 입력 필드 테두리
                ),
                validator: _idValidator, // 아이디 유효성 검사 함수 연결
              ),
              const SizedBox(height: 20), // 입력 필드 간 간격 설정
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController, // 이메일 입력 컨트롤러 연결
                decoration: const InputDecoration(
                  labelText: '이메일', // 이메일 라벨 텍스트
                  border: OutlineInputBorder(), // 이메일 입력 필드 테두리
                ),
                keyboardType: TextInputType.emailAddress, // 이메일 형식 입력 키보드
                validator: _emailValidator, // 이메일 유효성 검사 함수 연결
              ),
              const SizedBox(height: 20), // 입력 필드 간 간격 설정
              // 비밀번호 입력 필드
              TextFormField(
                controller: _passwordController, // 비밀번호 입력 컨트롤러 연결
                decoration: const InputDecoration(
                  labelText: '비밀번호', // 비밀번호 라벨 텍스트
                  border: OutlineInputBorder(), // 비밀번호 입력 필드 테두리
                ),
                obscureText: true, // 비밀번호는 가려서 표시
                validator: _passwordValidator, // 비밀번호 유효성 검사 함수 연결
              ),
              const SizedBox(height: 20), // 입력 필드 간 간격 설정
              // 회원가입 버튼
              ElevatedButton(
                onPressed: _submitForm, // 버튼 클릭 시 폼 제출 처리
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Colors.grey[300],
                  ), // 버튼 배경색 연한 회색
                  foregroundColor: MaterialStateProperty.all(
                    Colors.black,
                  ), // 버튼 글씨 색상 검정색
                ),
                child: const Text('회원가입'), // 버튼 텍스트
              ),
            ],
          ),
        ),
      ),
    );
  }
}