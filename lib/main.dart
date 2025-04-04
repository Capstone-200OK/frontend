import 'package:flutter/material.dart';
import 'package:my_desktop_app/screens/login_screen.dart'; // 로그인 화면 불러오기

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
      home: const LoginScreen(), // 로그인 화면을 초기 화면으로 설정
    );
  }
}
