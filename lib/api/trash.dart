import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 환경 설정에서 BaseUrl 가져오기
String baseUrl = dotenv.get("BaseUrl");

// API URL들
final String moveToTrashUrl = '$baseUrl/trash/move'; 
final String restoreFromTrashUrl = '$baseUrl/trash/restore';
final String deleteFromTrashUrl = '$baseUrl/trash/delete';
final String listTrashUrl = '$baseUrl/trash/list';

// 폴더를 휴지통으로 이동하는 함수
Future<void> moveFolderToTrash(int userId, List<int> folderIds) async {
  final requestBody = {
    "userId": userId,
    "folderIds": folderIds,
    "fileIds": [], 
  };

  try {
    final response = await http.post(
      Uri.parse(moveToTrashUrl),
      body: json.encode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('폴더가 휴지통으로 이동되었습니다.');
    } else {
      throw Exception('폴더 이동 실패');
    }
  } catch (e) {
    print('오류 발생: $e');
  }
}

// 휴지통에서 복구하는 함수
Future<void> restoreFromTrash(List<int> trashIds) async {
  try {
    final response = await http.post(
      Uri.parse(restoreFromTrashUrl),
      body: json.encode(trashIds),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('휴지통에서 복구되었습니다.');
    } else {
      throw Exception('복구 실패');
    }
  } catch (e) {
    print('오류 발생: $e');
  }
}

// 휴지통에서 완전 삭제하는 함수
Future<void> deleteFromTrash(List<int> trashIds) async {
  try {
    final response = await http.delete(
      Uri.parse(deleteFromTrashUrl),
      body: json.encode(trashIds),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('휴지통에서 완전 삭제되었습니다.');
    } else {
      throw Exception('완전 삭제 실패');
    }
  } catch (e) {
    print('오류 발생: $e');
  }
}

// 휴지통 목록 조회 함수
Future<List<Map<String, dynamic>>> fetchTrashList(int userId) async {
  try {
    final response = await http.get(Uri.parse('$listTrashUrl/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('휴지통 목록 조회 실패');
    }
  } catch (e) {
    print('오류 발생: $e');
    return [];
  }
}
