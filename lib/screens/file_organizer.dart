import 'dart:convert';
import 'package:http/http.dart' as http;

class FileOrganizer {
  final String baseUrl;

  FileOrganizer({required this.baseUrl});

  // 파일 자동 분류 시작 요청
  Future<void> startFileOrganization({
    required int folderId,
    required String mode,
    required int destinationFolderId,
  }) async {
    final uri = Uri.parse('$baseUrl/organize/start'); // 엔드포인트 URL

    // 요청 바디 설정
    final body = jsonEncode({
      "folderId": folderId,
      "mode": mode,
      "destinationFolderId": destinationFolderId,
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: body,
      );

      // 응답 처리
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("✅ ${responseBody['message']}"); // 성공 메시지 출력
      } else {
        final responseBody = jsonDecode(response.body);
        print("❌ 실패: ${responseBody['error']}"); // 실패 메시지 출력
      }
    } catch (e) {
      print("⚠️ 에러 발생: $e");
    }
  }
}
