import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

/// 폴더 생성 화면 위젯
class FolderCreateScreen extends StatefulWidget {
  final Function(String) onCreateFolder; // 폴더 생성 후 실행할 콜백 함수
  final int parentFolderId; // 부모 폴더 ID

  const FolderCreateScreen({Key? key, required this.onCreateFolder, required this.parentFolderId})
    : super(key: key);

  @override
  State<FolderCreateScreen> createState() => _FolderCreateScreenState();
}

class _FolderCreateScreenState extends State<FolderCreateScreen> {
  final TextEditingController _folderNameController = TextEditingController(); // 폴더 이름 입력 컨트롤러
  bool _isLoading = false; // 로딩 상태
  String _message = ''; // 사용자에게 보여줄 메시지
  String url = dotenv.get("BaseUrl"); // .env에서 API 기본 URL 가져오기
  //final int userId = 1;
  late final int parentFolderId;
  @override
  void initState() {
    super.initState();
    parentFolderId = widget.parentFolderId; // 전달받은 부모 폴더 ID 저장
  }

  // 폴더 생성 요청 함수
  Future<void> createFolder() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId; // Provider로부터 사용자 ID 가져오기
    final folderName = _folderNameController.text.trim(); // 폴더 이름 공백 제거

    if (folderName.isEmpty) {
      setState(() {
        _message = '폴더 이름을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final URL = Uri.parse('$url/folder/add'); // 폴더 생성 API 엔드포인트

    try {
      final response = await http.post(
        URL,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": folderName,
          "userId": userId,
          "parentFolderId": parentFolderId,
        }),
      );

      setState(() {
        _isLoading = false;
        if (response.statusCode == 200 || response.statusCode == 201) {
          _message = '폴더 생성 성공!';
          _folderNameController.clear();
          widget.onCreateFolder(folderName); // 콜백 실행
          Navigator.pop(context); // 다이얼로그 닫기

        } else {
          _message = '실패: ${response.statusCode} - ${response.body}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '서버와의 연결에 실패했습니다: $e';
      });
    }
  }

  // 다이얼로그 UI 구성
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        '새 폴더 생성',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontFamily: 'APPLESDGOTHICNEOEB',
          color: Colors.black,
        ),
      ),
      content: SizedBox(
        width: 100,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 폴더 이름 입력 필드
            Container(
              height: 45, 
              child: TextField(
                controller: _folderNameController,
                decoration: const InputDecoration(
                  labelText: '폴더 이름',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'APPLESDGOTHICNEOR',
                  ),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 12,
                  ), 
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ), 
              ),
            ),
           
            
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center, // 버튼 가운데 정렬
      actions: [
        // 취소 버튼
        TextButton(
          onPressed: () {
            Navigator.pop(context); // 다이얼로그 닫기
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            side: BorderSide(
              color:  Color(0xFF455A64),
              width: 1, 
            ),
          ),
          child: const Text(
            '취소',
            style: TextStyle(fontSize: 13, fontFamily: 'APPLESDGOTHICNEOR'),
          ),
        ),
        // 만들기 버튼
        TextButton(
          onPressed: createFolder, // 폴더 생성 함수 호출
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Color(0xFF263238),
          ),
          child: const Text(
            '만들기',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'APPLESDGOTHICNEOR',
              color: Colors.white,
            ),
          ),
        ),
        
      ],
      
    );
  }
}
