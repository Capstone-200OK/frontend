import 'dart:convert';
import 'package:http/http.dart' as http;

/// 파일 자동 분류 기능을 담당하는 클래스
class FileOrganizer {
  final String baseUrl;

  FileOrganizer({required this.baseUrl});

  // 파일 자동 분류 시작 요청 메서드
  Future<void> startFileOrganization({
    required int folderId, // 분류할 원본 폴더 ID
    required String mode, // 분류 모드
    required int destinationFolderId,
  }) async {
    final uri = Uri.parse('$baseUrl/organize/start'); // API 엔드포인트 URL 설정

    // 요청 본문 설정 ( JSON 형식 )
    final body = jsonEncode({
      "folderId": folderId,
      "mode": mode,
      "destinationFolderId": destinationFolderId,
    });

    try {
      // HTTP POST 요청 보내기
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"}, // JSON 형식 명시
        body: body,
      );

      // 응답 상태 코드가 200이면 성공
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes); // 한글 깨짐 방지
        final data = jsonDecode(decoded); // JSON 디코딩
        print(data); // 디버깅용 출력
        final responseBody = jsonDecode(data); // 응답 메시지 파싱
        print("✅ ${responseBody['message']}"); // 성공 메시지 출력
      } else {
        // 실패 응답 처리
        final responseBody = jsonDecode(response.body);
        print("❌ 실패: ${responseBody['error']}"); // 에러 메시지 출력
      }
    } catch (e) {
      // 요청 중 예외 발생 시 출력
      print("⚠️ 에러 발생: $e");
    }
  }
}