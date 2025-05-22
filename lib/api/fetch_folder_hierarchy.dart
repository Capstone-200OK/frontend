import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 폴더 계층 구조를 가져오는 비동기 함수
Future<FolderItem?> fetchFolderHierarchy(int folderId) async {
   // .env 파일에서 BaseUrl 불러오기
  final String baseUrl = dotenv.get('BaseUrl');
  final url = Uri.parse('$baseUrl/folder/hierarchy/$folderId');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // 응답 본문을 UTF-8로 디코딩하여 한글 깨짐 방지
      final decoded = utf8.decode(response.bodyBytes); 
      final data = jsonDecode(decoded);
      print(data);
      return FolderItem.fromJson(data);
    } else {
      // 서버 오류 출력
      print("❌ 서버 오류: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    // 요청 중 예외 발생 시 출력
    print("⚠️ 요청 중 에러 발생: $e");
    return null;
  }
}