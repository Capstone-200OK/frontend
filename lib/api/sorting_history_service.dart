import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 파일 정리 이력 관련 API 호출을 담당하는 서비스 클래스
class SortingHistoryService {
  // 특정 정리 작업(sortingId)에 대한 파일 이력 목록 조회
  static Future<List<Map<String, String>>> fetchSortingHistory(
    int sortingId, int userId,
  ) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse("$baseUrl/sorting-history/selectedList/$sortingId/$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> histories = data['fileHistories']; // 파일 이력 리스트

        // 각 이력을 Map<String, String> 형태로 변환
        return histories.map<Map<String, String>>((dynamic history) {
          final previousPath = history['previousFilePath'] as String; // 정리 전 경로
          final currentPath = history['currentFilePath'] as String; // 정리 후 경로
          final fileName = previousPath.split('/').last; // 파일 이름 추출
 
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

  // 사용자의 최신 정리 이력 ID를 조회
  static Future<int?> fetchLatestSortingHistoryId(int userId) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse('$baseUrl/sorting-history/latest-id/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final latestId = data['latestSortingHistoryId']; // 최신 정리 ID 추출
        

        if (latestId != null) {
          return latestId as int; // 성공 시 정수로 반환
        }
      } else {
        print('최신 sortingId 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('최신 sortingId 요청 중 에러: $e');
    }

    return null; // 실패 시 null 반환
  }

  // 사용자의 정리 이력 중 특정 날짜에 해당하는 정리 ID 조회
  static Future<int?> fetchSortingIdByDate(int userId, DateTime targetDate) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse('$baseUrl/sorting-history/list/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (final entry in data) {
          final dateString = entry['sortingDate']; // ex: "2024-04-30 18:22"
          final id = int.tryParse(entry['sortingId']); // 문자열 -> 정수 변환

          // 날짜 문자열이 대상 날짜와 (분 단위까지) 일치하는지 확인
          if (dateString.startsWith(targetDate.toString().substring(0, 16))) {
            return id;
          }
        }
      }
    } catch (e) {
      print('날짜로 sortingId 찾기 실패: $e');
    }

    return null; // 조건에 맞는 ID가 없거나 에러 시 null 반환
  }
}