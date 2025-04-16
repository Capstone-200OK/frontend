import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/file_item.dart';

class FileSortyScreen extends StatelessWidget {
  final List<FileItem> files;
  final String username;

  const FileSortyScreen({super.key, required this.files, required this.username});

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
                        _sortButton('내용'),
                        _sortButton('제목'),
                        _sortButton('날짜'),
                        _sortButton('유형'),
                      ],
                    )
                  ],
                )
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '파일 저장 위치',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF45525B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 정리 로직 실행
                  },
                  icon: const Icon(Icons.flight_takeoff, color: Colors.white),
                  label: const Text(
                    '정리하기',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _sortButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}
