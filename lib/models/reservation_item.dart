/// 예약 목록을 확인할 수 있는 모델 클래스
class Reservation {
  final int taskId;               // 예약 작업 ID
  final int userId;               // 사용자 ID
  final int previousFolderId;     // 원본 폴더 ID (이전 위치)
  final int newFolderId;          // 이동할 폴더 ID (새 위치)
  final String previousFoldername; // 원본 폴더 이름
  final String newFoldername;      // 새 폴더 이름
  final String criteria;           // 정렬 기준 (예: TITLE, DATE 등)
  final String interval;           // 반복 주기 (예: DAILY, WEEKLY 등)
  final DateTime nextExecuted;     // 다음 예약 실행 시간

  // 생성자
  Reservation({
    required this.taskId,
    required this.userId,
    required this.previousFolderId,
    required this.newFolderId,
    required this.previousFoldername,
    required this.newFoldername,
    required this.criteria,
    required this.interval,
    required this.nextExecuted,
  });

  // JSON 데이터를 Reservation 객체로 변환
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      taskId: json['taskId'],                                 // 작업 ID
      userId: json['userId'],                                 // 사용자 ID
      previousFolderId: json['previousFolderId'],             // 이전 폴더 ID
      newFolderId: json['newFolderId'],                       // 새 폴더 ID
      previousFoldername: json['previousFolderName'],         // 이전 폴더 이름
      newFoldername: json['newFolderName'],                   // 새 폴더 이름
      criteria: json['criteria'],                             // 정렬 기준
      interval: json['interval'],                             // 반복 주기
      nextExecuted: DateTime.parse(json['nextExecuted']),     // 다음 실행 시각
    );
  }
}
