import 'package:flutter/material.dart';
//import 'package:flutter_application_1/screens/login_screen.dart'; // 로그인 화면 불러오기
import 'package:flutter_application_1/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 로그인 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const PersonalScreen(username: '현서'), // 로그인 화면을 초기 화면으로 설정
      //home: const HomeScreen(username: '현서'),
      home: const LoginScreen(),
    );
  }
}
