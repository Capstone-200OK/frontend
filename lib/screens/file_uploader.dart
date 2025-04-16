import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:flutter_dotenv/flutter_dotenv.dart';


class FileUploader {
  final String baseUrl;

  FileUploader({required this.baseUrl});

  Future<void> uploadFiles({
    required File file,
    required int userId,
    required int folderId
  }) async {
    final uri = Uri.parse('$baseUrl/file/upload'); // 예시 엔드포인트
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileType = fileName.split('.').last;
    final fileSize = await file.length();

    final body = {
      "name": fileName,
      "filePath": "/Root/$fileName",
      "fileType": fileType,
      "size": fileSize,
      "userId": userId,
      "folderId": 1,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ 파일 메타데이터 업로드 성공");
      } else {
        print("❌ 실패: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ 에러 발생: $e");
    }
  }
}