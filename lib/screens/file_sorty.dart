import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/file_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileSortyScreen extends StatefulWidget {
  final List<FileItem> files;
  final String username;
  final int sourceFolderId;
  final int destinationFolderId;

  const FileSortyScreen({
    super.key,
    required this.files,
    required this.username,
    required this.sourceFolderId,
    required this.destinationFolderId,
  });

  @override
  State<FileSortyScreen> createState() => _FileSortyScreenState();
}

class _FileSortyScreenState extends State<FileSortyScreen> {
  String? selectedMode;
  late String url;

  @override
  void initState() {
    super.initState();
    url = dotenv.get("BaseUrl");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 600,
        height: 450,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF45525B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '파일 분류를 시작합니다 !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('제외하고 싶은 항목이 있나요?'),
                      const SizedBox(height: 8),
                      TextFormField(initialValue: '학생회'),
                      const SizedBox(height: 10),
                      TextFormField(),
                      const SizedBox(height: 10),
                      TextFormField(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('목적지 폴더는 정해진 건가요?'),
                      const SizedBox(height: 8),
                      TextFormField(),
                      const SizedBox(height: 10),
                      TextFormField(),
                      const SizedBox(height: 10),
                      TextFormField(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('정리 기준을 선택해 주세요!'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _sortButton(context, '내용', 'content'),
                        _sortButton(context, '제목', 'title'),
                        _sortButton(context, '날짜', 'date'),
                        _sortButton(context, '유형', 'type'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: '파일 저장 위치'),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45525B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedMode == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('정렬 기준을 선택해 주세요.')),
                      );
                      return;
                    }

                    final response = await http.post(
                      Uri.parse('$url/organize/start'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "folderId": widget.sourceFolderId,
                        "mode": selectedMode,
                        "destinationFolderId": widget.destinationFolderId,
                      }),
                    );

                    Navigator.of(context).pop();

                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('자동 정리가 시작되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('정리 요청 실패: ${response.statusCode}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.flight_takeoff, color: Colors.white),
                  label: const Text(
                    '정리하기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortButton(BuildContext context, String label, String mode) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedMode == mode ? Colors.black : Colors.white,
        foregroundColor: selectedMode == mode ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          selectedMode = mode;
        });
      },
      child: Text(label),
    );
  }
}
