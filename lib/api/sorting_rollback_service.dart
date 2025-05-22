import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 자동 분류 되돌리기(롤백)를 처리하는 서비스 클래스
class SortingRollbackService {
  // 정리 작업(sortingId)을 기준으로 롤백 요청을 보냄
  static Future<bool> rollbackSorting(int sortingId) async {
    String baseUrl = dotenv.get("BaseUrl"); // .env에서 API 기본 주소 가져오기

    try {
      // 롤백 요청을 보낼 URI 구성
      final uri = Uri.parse('$baseUrl/sorting-history/rollback/$sortingId');
      // POST 요청 전송
      final response = await http.post(uri);

      // 성공 시 true 반환
      if (response.statusCode == 200) {
        print("자동 분류 되돌리기 성공!");
        return true;
      } else {
        // 실패 시 상태 코드 출력 및 false 반환
        print("실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // 예외 발생 시 메시지 출력 및 false 반환
      print("에러 발생: $e");
      return false;
    }
  }
}
