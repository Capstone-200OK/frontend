import 'dart:io';
import 'package:http/http.dart' as http;

class FileUploader {
  final String baseUrl;

  FileUploader({required this.baseUrl});

  Future<void> uploadFiles({
    required List<File> files,
    required String name,
    required int userId,
    int? parentFolderId,
  }) async {
    final uri = Uri.parse('http://223.194.137.216:8080/folder/add');
    final request = http.MultipartRequest('POST', uri);

    // JSON 필드 추가
    request.fields['name'] = name;
    request.fields['userId'] = userId.toString();
    request.fields['parentFolderId'] = parentFolderId?.toString() ?? 'null';

    // 파일들 추가
    for (var file in files) {
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'files', // 서버가 기대하는 필드명
        fileBytes,
        filename: file.path.split(Platform.pathSeparator).last,
      );
      request.files.add(multipartFile);
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('파일 업로드 성공');
      } else {
        print(' 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print(' 에러 발생: $e');
    }
  }
}