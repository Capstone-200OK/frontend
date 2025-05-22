// lib/api/file_reservation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 파일 예약 작업을 처리하는 서비스 클래스
class FileReservationService {
  // 예약 추가 메서드
  static Future<bool> addReservation({
    required int userId, // 사용자 ID
    required int previousFolderId, // 이전(기준) 폴더 ID
    required int newFolderId, // 이동할 대상 폴더 ID
    required String criteria, // 정렬 기준 (예: TYPE, TITLE, DATE, CONTENT)
    required String interval, // 실행 주기 (예: DAILY, WEEKLY, MONTHLY)
    required DateTime nextExecuted, // 다음 실행 시간
  }) async {
    final baseUrl = dotenv.get('BaseUrl'); // 환경변수에서 BaseUrl 가져오기
    final url = Uri.parse('$baseUrl/scheduledTask/add'); // 예약 추가 API URL

    // 요청 본문(JSON) 구성
    final body = jsonEncode({
      "userId": userId,
      "previousFolderId": previousFolderId,
      "newFolderId": newFolderId,
      "criteria": criteria,
      "interval": interval,
      "nextExecuted": nextExecuted.toIso8601String(), // ISO 8601 형식으로 날짜 변환
    });

    try {
      // POST 요청 전송
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"}, // JSON 형식 명시
        body: body,
      );

      // 상태 코드 200 또는 201이면 성공
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('예약 추가 성공!');
        return true;
      } else {
        // 실패 시 상태 코드와 응답 본문 출력
        print('예약 추가 실패: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      // 요청 중 에러 발생 시 출력
      print('예약 추가 중 에러 발생: $e');
      return false;
    }
  }

  // 예약 수정 메서드
  static Future<bool> modifyReservation({
    required int taskId, // 수정할 예약 작업 ID
    required int userId,
    required int previousFolderId,
    required int newFolderId,
    required String criteria,
    required String interval,
    required DateTime nextExecuted,
  }) async {
    final baseUrl = dotenv.get("BaseUrl"); // 환경변수에서 BaseUrl 가져오기
    final url = Uri.parse('$baseUrl/scheduledTask/modify/$taskId'); // 예약 수정 API URL

    // 요청 본문(JSON) 구성
    final body = jsonEncode({
      'userId': userId,
      'previousFolderId': previousFolderId,
      'newFolderId': newFolderId,
      'criteria': criteria,
      'interval': interval,
      'nextExecuted': nextExecuted.toIso8601String(),
    });

    try {
      // POST 요청 전송
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // 상태 코드 200 또는 201이면 성공
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('예약 수정 성공!');
        return true;
      } else {
        // 실패 시 상태 코드와 응답 본문 출력
        print('예약 수정 실패: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      // 요청 중 에러 발생 시 출력
      print('예약 수정 중 에러 발생: $e');
      return false;
    }
  }
}
