import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/folder_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<FolderItem?> fetchFolderHierarchy(int folderId) async {
  final String baseUrl = dotenv.get('BaseUrl'); // .env에 저장한 경우
  final url = Uri.parse('$baseUrl/folder/hierarchy/$folderId');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return FolderItem.fromJson(jsonData);
    } else {
      print("❌ 서버 오류: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    print("⚠️ 요청 중 에러 발생: $e");
    return null;
  }
}
