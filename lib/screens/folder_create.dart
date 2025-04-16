//폴더를 새로 추가할 수 있는 창
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FolderCreateScreen extends StatefulWidget {
  const FolderCreateScreen({super.key});

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
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final URL = Uri.parse('$url/folder/add');
    final response = await http.post(
      URL,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": _folderNameController.text,
        "userId": 1,
        "parentFolderId": 1,
      }),
    );

    setState(() {
      _isLoading = false;
      print('📡 폴더 만들기 요청 주소: $url');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _message = '폴더 생성 성공!';
        _folderNameController.clear();
      } else {
        _message = '실패: ${response.statusCode} - ${response.body}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📁 폴더 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _folderNameController,
              decoration: const InputDecoration(
                labelText: '폴더 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: createFolder,
                  child: const Text('폴더 만들기'),
                ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
