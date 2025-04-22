import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SortingRollbackService {
  static Future<bool> rollbackSorting(int sortingId) async {
    String baseUrl = dotenv.get("BaseUrl");

    try {
      final uri = Uri.parse('$baseUrl/sorting-history/rollback/$sortingId');
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        print("자동 분류 되돌리기 성공!");
        return true;
      } else {
        print("실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("에러 발생: $e");
      return false;
    }
  }
}
