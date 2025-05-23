import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 폴더 권한 부여(초대) 다이얼로그
class FolderGrantDialog extends StatefulWidget {
  final int folderId; // 권한을 부여할 폴더 ID

  const FolderGrantDialog({super.key, required this.folderId});

  @override
  State<FolderGrantDialog> createState() => _FolderGrantDialogState();
}

class _FolderGrantDialogState extends State<FolderGrantDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _read = false; // 읽기 권한
  bool _write = false; // 쓰기 권한
  bool _delete = false; // 삭제 권한
  bool _isLoading = false; // 로딩 상태
  String _message = ''; // 에러 또는 성공 메시지
  final String url = dotenv.get("BaseUrl");

  // 체크된 권한들을 정수값으로 변환 (chmod 형식)
  int getChmod() {
    int chmod = 0;
    if (_read) chmod += 1;
    if (_write) chmod += 2;
    if (_delete) chmod += 4;
    return chmod;
  }

  // 사용자에게 폴더 권한을 부여하는 API 호출
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

      // 이메일로 사용자 정보 조회
      final userRes = await http.get(Uri.parse('$url/user/by-email/$email'));
      if (userRes.statusCode != 200) {
        setState(() {
          _message = '해당 이메일의 유저를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final userId = jsonDecode(userRes.body)['userId'];
      final chmod = getChmod(); // 권한값 계산

      // 권한 부여 요청
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
        Navigator.pop(context); // 다이얼로그 닫기
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        '폴더에 사용자 초대',
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'APPLESDGOTHICNEOEB'
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이메일 입력 필드
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '사용자 이메일'),
          ),
          const SizedBox(height: 12),
          // 권한 체크박스들
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
          // 로딩 인디케이터 및 메시지
          if (_isLoading) const CircularProgressIndicator(),
          if (_message.isNotEmpty)
            Text(_message, style: const TextStyle(color: Colors.red)),
        ],
      ),

      // 하단 버튼들
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context); // 다이얼로그 닫기
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black87),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
           '취소',
           style: TextStyle(color: Colors.black87),
            ),
        ),
        OutlinedButton(
          onPressed: grantPermission,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black87), // 테두리 색
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            '초대',
            style: TextStyle(color: Colors.black87),
            ),
        ),
      ],
    );
  }
}
