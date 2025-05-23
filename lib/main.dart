import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart'; // 홈 화면 불러오기
import 'models/counter_model.dart'; // provider 모델 import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/notification_button.dart'; // NotificationButton 위젯
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';

// 전역에서 사용할 ScaffoldMessengerKey
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// 전역 Navigator Key (네비게이션 라우팅에 사용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 알림 상태를 전역에서도 접근 가능하도록 설정
late NotificationProvider globalNotificationProvider;

void main() async {
  // 비동기 초기화
  WidgetsFlutterBinding.ensureInitialized();  // runApp 전에 비동기 작업을 위해 필요
  await dotenv.load(fileName: ".env");    // .env 파일 로딩(API 주소 등 환경변수 사용 가능)
  
  // 여러 Provider를 앱 전역에 설정
  runApp(MultiProvider(
    providers: [
      // 사용자 정보 상태 관리 Provider 등록
      ChangeNotifierProvider(create: (_) => UserProvider()),
      // 알림 상태 관리 Provider 등록
      ChangeNotifierProvider(create: (_) {
        globalNotificationProvider = NotificationProvider();
        return globalNotificationProvider;
      }),
    ],
    child: const MyApp(), // 앱 실행 시작점
  ));
}

// 앱의 최상위 위젯 정의
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterModel(), // 예시용 카운터 모델 Provider
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // 디버그 배너 제거
        title: 'Flutter 로그인 앱', // 앱 제목
        scaffoldMessengerKey: rootScaffoldMessengerKey, // 전역 메시지 키 설정
        theme: ThemeData(primarySwatch: Colors.blue), // 앱 테마 설정
        home: const LoginScreen() // 앱 시작 시 보여줄 첫 화면 (로그인 화면)
      ),
    );
  }
}