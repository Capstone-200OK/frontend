import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/important_file_item.dart';
import 'package:flutter_application_1/models/important_folder_item.dart';

// .env에서 BaseUrl 가져오기
final String baseUrl = dotenv.get("BaseUrl");

// 중요 문서함 관련 API 엔드포인트 정의
final String addToImportantUrl = '$baseUrl/important-bin/add';
final String removeFromImportantUrl = '$baseUrl/important-bin/remove';
final String fetchImportantFilesUrl = '$baseUrl/important-bin/files';
final String fetchImportantFoldersUrl = '$baseUrl/important-bin/folders';

// 중요 문서함에 파일 또는 폴더 추가
Future<void> addToImportant({
  required int userId, // 사용자 ID
  int? fileId, // 파일 ID (선택적)
  int? folderId, // 폴더 ID (선택적)
}) async {
  // 요청 바디 구성 (fileId 또는 folderId 중 하나만 포함 가능)
  final requestBody = {
    "userId": userId,
    if (fileId != null) "fileId": fileId,
    if (folderId != null) "folderId": folderId,
  };

  try {
    final response = await http.post(
      Uri.parse(addToImportantUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    // 실패 시 예외 발생
    if (response.statusCode != 200) {
      throw Exception('중요 문서함 추가 실패: ${response.body}');
    }
  } catch (e) {
    print('중요 문서함 추가 오류: $e');
  }
}

// 중요 문서함에서 항목 제거 (파일 또는 폴더)
Future<void> removeFromImportant(int importantId) async {
  try {
    final response = await http.delete(
      Uri.parse('$removeFromImportantUrl/$importantId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('중요 문서함 제거 실패: ${response.body}');
    }
  } catch (e) {
    print('중요 문서함 제거 오류: $e');
  }
}

// 사용자 ID를 기반으로 중요 파일 목록 조회
Future<List<ImportantFileItem>> fetchImportantFiles(int userId) async {
  final response = await http.get(Uri.parse('$fetchImportantFilesUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    // JSON 리스트를 모델 리스트로 변환
    return jsonData.map((item) => ImportantFileItem.fromJson(item)).toList();
  } else {
    throw Exception('중요 파일 조회 실패');
  }
}

// 사용자 ID를 기반으로 중요 폴더 목록 조회
Future<List<ImportantFolderItem>> fetchImportantFolders(int userId) async {
  final response = await http.get(Uri.parse('$fetchImportantFoldersUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    // JSON 리스트를 모델 리스트로 변환
    return jsonData.map((item) => ImportantFolderItem.fromJson(item)).toList();
  } else {
    throw Exception('중요 폴더 조회 실패');
  }
}
