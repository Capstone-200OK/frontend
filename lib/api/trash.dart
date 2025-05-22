import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/models/trash_file_item.dart';
import 'package:flutter_application_1/models/trash_folder_item.dart';

// .env에서 API 기본 URL 불러오기
final String baseUrl = dotenv.get("BaseUrl");

// 휴지통 관련 API 엔드포인트 정의
final String moveToTrashUrl = '$baseUrl/trash/move'; // 휴지통으로 이동
final String restoreFromTrashUrl = '$baseUrl/trash/restore'; // 휴지통에서 복구
final String deleteFromTrashUrl = '$baseUrl/trash/delete'; // 휴지통에서 완전 삭제
final String fetchDeletedFilesUrl = '$baseUrl/trash/files'; // 삭제된 파일 조회
final String fetchDeletedFoldersUrl = '$baseUrl/trash/folders'; // 삭제된 폴더 조회

// 파일/폴더를 휴지통으로 이동시키는 함수
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

// 휴지통에서 항목을 복구하는 함수
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

// 휴지통에서 항목을 완전히 삭제하는 함수
Future<void> deleteFromTrash(List<int> trashIds) async {
  try {
    final response = await http.post(
      Uri.parse(deleteFromTrashUrl),
      body: jsonEncode(trashIds), // 삭제할 항목 ID 목록
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('삭제 실패: ${response.body}');
    }
  } catch (e) {
    print('삭제 오류: $e');
  }
}

// 삭제된 파일 목록 조회
Future<List<TrashFileItem>> fetchDeletedFiles(int userId) async {
  final response = await http.get(Uri.parse('$fetchDeletedFilesUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    // JSON 데이터를 TrashFileItem 리스트로 변환
    return jsonData.map((item) => TrashFileItem.fromJson(item)).toList();
  } else {
    throw Exception('삭제된 파일 조회 실패');
  }
}

// 삭제된 폴더 목록 조회
Future<List<TrashFolderItem>> fetchDeletedFolders(int userId) async {
  final response = await http.get(Uri.parse('$fetchDeletedFoldersUrl/$userId'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    // JSON 데이터를 TrashFolderItem 리스트로 변환
    return jsonData.map((item) => TrashFolderItem.fromJson(item)).toList();
  } else {
    throw Exception('삭제된 폴더 조회 실패');
  }
}
