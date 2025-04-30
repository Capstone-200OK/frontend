// lib/models/reservation.dart
//예약 목록을 확인할 수 있는 모델 
class Reservation {
  final int taskId;
  final int userId;
  final String previousFoldername;
  final String newFoldername;
  final String criteria;
  final String interval;
  final DateTime nextExecuted;

  Reservation({
    required this.taskId,
    required this.userId,
    required this.previousFoldername,
    required this.newFoldername,
    required this.criteria,
    required this.interval,
    required this.nextExecuted,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      taskId: json['taskId'],
      userId: json['userId'],
      previousFoldername: json['previousFolderName'],
      newFoldername: json['newFolderName'],
      criteria: json['criteria'],
      interval: json['interval'],
      nextExecuted: DateTime.parse(json['nextExecuted']),
    );
  }
}
