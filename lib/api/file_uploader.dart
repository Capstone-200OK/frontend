import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// 파일 업로드를 처리하는 클래스
class FileUploader {
  final String baseUrl; // API 서버의 기본 URL
  final String s3BaseUrl; // S3 또는 저장소의 기본 URL
  FileUploader({required this.baseUrl, required this.s3BaseUrl});

  // 파일을 업로드하는 메서드
  Future<void> uploadFiles({
    required File file, // 업로드할 파일
    required int userId, // 사용자 ID
    required int folderId, // 업로드 대상 폴더 ID
    required String currentFolderPath, // 현재 폴더 경로 (예: /Documents/Images)
  }) async {
    final uri = Uri.parse('$baseUrl/file/upload'); // 업로드 API 엔드포인트

    // 파일 이름 추출
    final fileName = file.path.split(Platform.pathSeparator).last;
    
    // MIME 타입 추론 (예: image/jpeg)
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeParts = mimeType.split('/'); // MIME 타입 분해 (예: ['image', 'jpeg'])

    // 파일 크기 및 확장자 정보 추출
    final fileSize = await file.length();
    final fileExt = fileName.contains('.') ? fileName.split('.').last : '';

    // S3 URL에 해당 파일 경로 붙이기
    final fileUrl = "$s3BaseUrl$fileName";

    // 메타데이터 구성
    final meta = {
      "name": fileName,
      "filePath": "$currentFolderPath/$fileName", // 실제 경로 (서버에서 덮어씌워질 수도 있음)
      "fileType": fileExt, // 파일 확장자
      "size": fileSize, // 파일 크기
      "userId": userId, // 사용자 ID
      "folderId": folderId, // 폴더 ID
      "fileUrl": fileUrl, // 저장될 전체 파일 URL
    };

    // Multipart 요청 객체 생성
    final request = http.MultipartRequest('POST', uri);

    // 1. 'meta' 필드를 JSON 문자열로 추가
    request.fields['meta'] = jsonEncode(meta);

    // 2. 'file' 필드에 실제 파일 추가
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]), // Content-Type 지정
    ));

    try {
      // 요청 보내기
      final streamedResponse = await request.send();

      // 응답 본문 읽기
      final response = await http.Response.fromStream(streamedResponse);

      // 업로드 성공 여부 확인
      if (response.statusCode == 200) {
        print("✅ 파일 업로드 성공!");
        print("응답: ${response.body}");
      } else {
        print("❌ 업로드 실패: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      // 네트워크 또는 예외 발생 시
      print("⚠️ 네트워크 오류 발생: $e");
    }
  }
}