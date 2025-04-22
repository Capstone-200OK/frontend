import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class FileUploader {
  final String baseUrl;

  FileUploader({required this.baseUrl});

  Future<void> uploadFiles({
    required File file,
    required int userId,
    required int folderId,
  }) async {
    final uri = Uri.parse('$baseUrl/file/upload');

    final fileName = file.path.split(Platform.pathSeparator).last;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeParts = mimeType.split('/'); // ['image', 'jpeg'] 같은 식

    final fileSize = await file.length();
    final fileExt = fileName.contains('.') ? fileName.split('.').last : '';

    final meta = {
      "name": fileName,
      "filePath": "/Root/$fileName", // 실제로는 덮어씌워질 예정
      "fileType": mimeType,
      "size": fileSize,
      "userId": userId,
      "folderId": folderId,
    };

    final request = http.MultipartRequest('POST', uri);

    // 1. meta 필드 (JSON 문자열로)
    request.fields['meta'] = jsonEncode(meta);

    // 2. file 필드
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("✅ 파일 업로드 성공!");
        print("응답: ${response.body}");
      } else {
        print("❌ 업로드 실패: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("⚠️ 네트워크 오류 발생: $e");
    }
  }
}