import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart'; // 홈홈 화면 불러오기
import 'models/counter_model.dart'; // provider 모델 import

//import 'package:flutter_application_1/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: MaterialApp(
        title: 'Flutter 로그인 앱',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomeScreen(username: '현서'),
      ),
    );
  }
}
