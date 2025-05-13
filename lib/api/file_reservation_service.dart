// lib/api/file_reservation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileReservationService {
  static Future<bool> addReservation({
    required int userId,
    required int previousFolderId,
    required int newFolderId,
    required String criteria, // 예: TYPE, TITLE, DATE, CONTENT
    required String interval, // 예: DAILY, WEEKLY, MONTHLY
    required DateTime nextExecuted,
  }) async {
    final baseUrl = dotenv.get('BaseUrl');
    final url = Uri.parse('$baseUrl/scheduledTask/add');

    final body = jsonEncode({
      "userId": userId,
      "previousFolderId": previousFolderId,
      "newFolderId": newFolderId,
      "criteria": criteria,
      "interval": interval,
      "nextExecuted": nextExecuted.toIso8601String(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('예약 추가 성공!');
        return true;
      } else {
        print('예약 추가 실패: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('예약 추가 중 에러 발생: $e');
      return false;
    }
  }

  static Future<bool> modifyReservation({
    required int taskId,
    required int userId,
    required int previousFolderId,
    required int newFolderId,
    required String criteria,
    required String interval,
    required DateTime nextExecuted,
  }) async {
    final baseUrl = dotenv.get("BaseUrl");
    final url = Uri.parse('$baseUrl/scheduledTask/modify/$taskId');

    final body = jsonEncode({
      'userId': userId,
      'previousFolderId': previousFolderId,
      'newFolderId': newFolderId,
      'criteria': criteria,
      'interval': interval,
      'nextExecuted': nextExecuted.toIso8601String(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('예약 수정 성공!');
        return true;
      } else {
        print('예약 수정 실패: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('예약 수정 중 에러 발생: $e');
      return false;
    }
  }
}
