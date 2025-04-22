import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FolderCreateScreen extends StatefulWidget {
  final Function(String) onCreateFolder;

  const FolderCreateScreen({
    Key? key,
    required this.onCreateFolder,
  }) : super(key: key);

  @override
  State<FolderCreateScreen> createState() => _FolderCreateScreenState();
}

class _FolderCreateScreenState extends State<FolderCreateScreen> {
  final TextEditingController _folderNameController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  String url = dotenv.get("BaseUrl");
  final int userId = 1;
  final int parentFolderId = 1;

  Future<void> createFolder() async {
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
          widget.onCreateFolder(folderName);  // 콜백 실행
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
      title: const Text(
        '새 폴더 생성',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _folderNameController,
              decoration: const InputDecoration(
                labelText: '폴더 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // 닫기
          },
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: createFolder,
          child: const Text('만들기'),
        ),
      ],
    );
  }
}