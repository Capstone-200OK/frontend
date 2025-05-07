import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/user_provider.dart';

class FolderCreateScreen extends StatefulWidget {
  final Function(String) onCreateFolder;
  final int parentFolderId;

  const FolderCreateScreen({Key? key, required this.onCreateFolder, required this.parentFolderId})
    : super(key: key);

  @override
  State<FolderCreateScreen> createState() => _FolderCreateScreenState();
}

class _FolderCreateScreenState extends State<FolderCreateScreen> {
  final TextEditingController _folderNameController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  String url = dotenv.get("BaseUrl");
  //final int userId = 1;
  late final int parentFolderId;
  @override
  void initState() {
    super.initState();
    parentFolderId = widget.parentFolderId;
  }
  Future<void> createFolder() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final folderName = _folderNameController.text.trim();

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

    final URL = Uri.parse('$url/folder/add');
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
            Container(
              height: 45, // TextField의 높이를 설정
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
                  ), // 패딩 조정
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'APPLESDGOTHICNEOR',
                ), // 실제 입력 텍스트의 폰트 크기
              ),
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 5,
                    fontFamily: 'APPLESDGOTHICNEOR',
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // 닫기
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            side: BorderSide(
              color:  Color(0xFF455A64), // 획(테두리) 색상
              width: 1, // 획(테두리) 두께
            ),
          ),
          child: const Text(
            '취소',
            style: TextStyle(fontSize: 13, fontFamily: 'APPLESDGOTHICNEOR'),
          ),
        ),
        TextButton(
          onPressed: createFolder,
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
