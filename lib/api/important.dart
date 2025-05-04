import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/important_file_item.dart';
import 'package:flutter_application_1/models/important_folder_item.dart';

final String baseUrl = dotenv.get("BaseUrl");

final String addToImportantUrl = '$baseUrl/important-bin/add';
final String removeFromImportantUrl = '$baseUrl/important-bin/remove';
final String fetchImportantFilesUrl = '$baseUrl/important-bin/files';
final String fetchImportantFoldersUrl = '$baseUrl/important-bin/folders';

Future<void> addToImportant({
  required int userId,
  int? fileId,
  int? folderId,
}) async {
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

    if (response.statusCode != 200) {
      throw Exception('중요 문서함 추가 실패: ${response.body}');
    }
  } catch (e) {
    print('중요 문서함 추가 오류: $e');
  }
}

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

Future<List<ImportantFileItem>> fetchImportantFiles(int userId) async {
  final response = await http.get(Uri.parse('$fetchImportantFilesUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((item) => ImportantFileItem.fromJson(item)).toList();
  } else {
    throw Exception('중요 파일 조회 실패');
  }
}

Future<List<ImportantFolderItem>> fetchImportantFolders(int userId) async {
  final response = await http.get(Uri.parse('$fetchImportantFoldersUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((item) => ImportantFolderItem.fromJson(item)).toList();
  } else {
    throw Exception('중요 폴더 조회 실패');
  }
}
