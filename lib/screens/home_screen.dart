import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/personal_screen.dart';
import 'package:flutter_application_1/components/navigation_drawer.dart';
import 'package:flutter_application_1/screens/recent_file_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/screens/cloud_screen.dart';
import 'dart:convert'; // for jsonDecode
import 'package:http/http.dart' as http; // for http.get
import 'package:flutter_dotenv/flutter_dotenv.dart'; // for dotenv.get
import 'package:flutter_application_1/components/search_bar_with_overlay.dart';
import 'package:flutter_application_1/api/websocket_service.dart';
import 'package:flutter_application_1/components/notification_button.dart'; // NotificationButton 위젯
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/notification_provider.dart';
import 'package:flutter_application_1/components/navigation_stack.dart';
import 'package:flutter_application_1/components/navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int? userId;
  late String url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userId = Provider.of<UserProvider>(context, listen: false).userId;
      url = dotenv.get("BaseUrl");
      if (userId != null) {
        WebSocketService().connect(context, userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/LOGO-text.png',
          height: 230,
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 111),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.history,
                    color: Color(0xff263238),
                  ),
                  onPressed: () {
                    final userId = Provider.of<UserProvider>(context, listen: false).userId;
                    NavigationStack.push('RecentFileScreen', arguments: {'username': widget.username, 'userId': userId});
                    NavigationStack.printStack();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecentFileScreen(
                          username: widget.username,
                          userId: userId,
                        ),
                      ),
                    );
                    // print('최근 항목 눌림');
                  },
                ),
                const NotificationButton(),
              ],
            ),
          ),
        ],
      ),
      drawer: NavigationDrawerWidget(
        username: widget.username,
        onFolderCreated: (folderName) {},
        folders: const [],
        scaffoldContext: context,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                '${widget.username}님, 안녕하세요',
                style: const TextStyle(
                  fontSize: 30,
                  fontFamily: 'APPLESDGOTHICNEOEB',
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    NavigationStack.push('PersonalScreen1', arguments: {
                      'username': widget.username,
                      'targetPathIds': null,
                    });
                    NavigationStack.printStack();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalScreen(
                          username: widget.username,
                          targetPathIds: null,
                        ),
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
                      Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xff263238),
                      ),
                      SizedBox(width: 8),
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
                const SizedBox(width: 150),
                ElevatedButton(
                  onPressed: () {
                    NavigationStack.push('CloudScreen1', arguments: {
                      'username': widget.username,
                    });

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CloudScreen(
                          username: widget.username,
                        ),
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
            const SizedBox(height: 237),
            SearchBarWithOverlay(
              baseUrl: dotenv.get("BaseUrl"),
              username: widget.username,
            ),
          ],
        ),
      ),
    );
  }
}
