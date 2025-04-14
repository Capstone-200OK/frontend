import 'package:flutter/material.dart';
import 'personal_screen.dart'; // FileItem 클래스 접근용 (같은 폴더에 있다고 가정)

class FileSortyScreen extends StatelessWidget {
  final List<FileItem> files;

  const FileSortyScreen({Key? key, required this.files}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 이름 기준 정렬
    final sortedFiles = [...files]..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('파일 정렬 결과'),
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: sortedFiles.length,
        itemBuilder: (context, index) {
          final file = sortedFiles[index];
          return ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file.name),
            subtitle: Text('${file.type} - ${file.sizeFormatted}'),
          );
        },
      ),
    );
  }
}
