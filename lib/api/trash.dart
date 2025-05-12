import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/trash_file_item.dart';
import 'package:flutter_application_1/models/trash_folder_item.dart';

final String baseUrl = dotenv.get("BaseUrl");

final String moveToTrashUrl = '$baseUrl/trash/move';
final String restoreFromTrashUrl = '$baseUrl/trash/restore';
final String deleteFromTrashUrl = '$baseUrl/trash/delete';
final String fetchDeletedFilesUrl = '$baseUrl/trash/files';
final String fetchDeletedFoldersUrl = '$baseUrl/trash/folders';

Future<void> moveToTrash(int userId, List<int> folderIds, List<int> fileIds) async {
  final requestBody = {
    "userId": userId,
    "folderIds": folderIds,
    "fileIds": fileIds,
  };

  try {
    final response = await http.post(
      Uri.parse(moveToTrashUrl),
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('휴지통 이동 실패: ${response.body}');
    }
  } catch (e) {
    print('휴지통 이동 오류: $e');
  }
}

Future<void> restoreFromTrash(List<int> trashIds) async {
  try {
    final response = await http.post(
      Uri.parse(restoreFromTrashUrl),
      body: jsonEncode(trashIds),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('복구 실패: ${response.body}');
    }
  } catch (e) {
    print('복구 오류: $e');
  }
}

Future<void> deleteFromTrash(List<int> trashIds) async {
  try {
    final response = await http.post(
      Uri.parse(deleteFromTrashUrl),
      body: jsonEncode(trashIds),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('삭제 실패: ${response.body}');
    }
  } catch (e) {
    print('삭제 오류: $e');
  }
}

Future<List<TrashFileItem>> fetchDeletedFiles(int userId) async {
  final response = await http.get(Uri.parse('$fetchDeletedFilesUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((item) => TrashFileItem.fromJson(item)).toList();
  } else {
    throw Exception('삭제된 파일 조회 실패');
  }
}

Future<List<TrashFolderItem>> fetchDeletedFolders(int userId) async {
  final response = await http.get(Uri.parse('$fetchDeletedFoldersUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((item) => TrashFolderItem.fromJson(item)).toList();
  } else {
    throw Exception('삭제된 폴더 조회 실패');
  }
}
