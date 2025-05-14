import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SortingHistoryService {
  static Future<List<Map<String, String>>> fetchSortingHistory(
    int sortingId, int userId,
  ) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse("$baseUrl/sorting-history/selectedList/$sortingId/$userId");
    

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
  static Future<int?> fetchSortingIdByDate(int userId, DateTime targetDate) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse('$baseUrl/sorting-history/list/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (final entry in data) {
          final dateString = entry['sortingDate']; // ex: "2024-04-30 18:22"
          final id = int.tryParse(entry['sortingId']);

          // 날짜 비교(분까지 포함)
          if (dateString.startsWith(targetDate.toString().substring(0, 16))) {
            return id;
          }
        }
      }
    } catch (e) {
      print('날짜로 sortingId 찾기 실패: $e');
    }

    return null;
  }
}