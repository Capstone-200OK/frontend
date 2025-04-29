import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SortingHistoryService {
  static Future<List<Map<String, String>>> fetchSortingHistory(
    int sortingId,
  ) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse("$baseUrl/sorting-history/selectedList/$sortingId");
    

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> histories = data['fileHistories'];

        return histories.map<Map<String, String>>((dynamic history) {
          final previousPath = history['previousFilePath'] as String;
          final currentPath = history['currentFilePath'] as String;
          final fileName = previousPath.split('/').last;

          return {
            'previousPath': previousPath,
            'currentPath': currentPath,
            'fileName': fileName,
          };
        }).toList();
      } else {
        print("요청 실패: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("에러 발생: $e");
      return [];
    }
  }

  static Future<int?> fetchLatestSortingHistoryId(int userId) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse('$baseUrl/sorting-history/latest-id/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final latestId = data['latestSortingHistoryId'];

        if (latestId != null) {
          return latestId as int;
        }
      } else {
        print('최신 sortingId 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('최신 sortingId 요청 중 에러: $e');
    }

    return null; // 실패 시 null 반환
  }
}
