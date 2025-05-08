import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FolderGrantDialog extends StatefulWidget {
  final int folderId;

  const FolderGrantDialog({super.key, required this.folderId});

  @override
  State<FolderGrantDialog> createState() => _FolderGrantDialogState();
}

class _FolderGrantDialogState extends State<FolderGrantDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _read = false;
  bool _write = false;
  bool _delete = false;
  bool _isLoading = false;
  String _message = '';
  final String url = dotenv.get("BaseUrl");

  int getChmod() {
    int chmod = 0;
    if (_read) chmod += 1;
    if (_write) chmod += 2;
    if (_delete) chmod += 4;
    return chmod;
  }

  Future<void> grantPermission() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          _message = '이메일을 입력해주세요.';
          _isLoading = false;
        });
        return;
      }

      final userRes = await http.get(Uri.parse('$url/user/by-email/$email'));
      if (userRes.statusCode != 200) {
        setState(() {
          _message = '해당 이메일의 유저를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final userId = jsonDecode(userRes.body)['userId'];
      final chmod = getChmod();

      final res = await http.post(
        Uri.parse('$url/folder-access/grant'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'folderId': widget.folderId,
          'chmod': chmod,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('권한 부여 성공')),
        );
      } else {
        setState(() {
          _message = '권한 부여 실패: ${res.body}';
        });
      }
    } catch (e) {
      setState(() {
        _message = '오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('폴더에 사용자 초대'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '사용자 이메일'),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('읽기'),
            value: _read,
            onChanged: (v) => setState(() => _read = v!),
          ),
          CheckboxListTile(
            title: const Text('쓰기'),
            value: _write,
            onChanged: (v) => setState(() => _write = v!),
          ),
          CheckboxListTile(
            title: const Text('삭제'),
            value: _delete,
            onChanged: (v) => setState(() => _delete = v!),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          if (_message.isNotEmpty)
            Text(_message, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: grantPermission,
          child: const Text('초대'),
        ),
      ],
    );
  }
}
