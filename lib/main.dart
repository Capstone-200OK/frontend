import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart'; // 홈홈 화면 불러오기
import 'models/counter_model.dart'; // provider 모델 import
//import 'package:flutter_application_1/screens/folder_create.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/notification_button.dart'; // NotificationButton 위젯
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late NotificationProvider globalNotificationProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // 1번코드
  await dotenv.load(fileName: ".env");    // 2번코드
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) {
        globalNotificationProvider = NotificationProvider();
        return globalNotificationProvider;
      }),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: MaterialApp(
        title: 'Flutter 로그인 앱',
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: ThemeData(primarySwatch: Colors.blue),
        //home: const HomeScreen(username: '현서'),
        //home: const FolderCreateScreen(),
        home: const LoginScreen()
      ),
    );
  }
}