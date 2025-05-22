/// 삭제된 파일(휴지통) 정보를 담는 모델 클래스
class TrashFileItem {
  final int trashId;         // 휴지통 항목 ID (고유 식별자)
  final int fileId;          // 원본 파일 ID
  final String fileName;     // 파일 이름
  final String fileType;     // 파일 타입 (예: pdf, jpg 등)
  final int size;            // 파일 크기 (바이트 단위)
  final DateTime deletedAt;  // 삭제된 날짜 및 시간

  // 생성자
  TrashFileItem({
    required this.trashId,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.size,
    required this.deletedAt,
  });

  // JSON 데이터를 TrashFileItem 객체로 변환
  factory TrashFileItem.fromJson(Map<String, dynamic> json) {
    return TrashFileItem(
      trashId: json['trashId'],                       // 휴지통 ID
      fileId: json['fileId'],                         // 파일 ID
      fileName: json['fileName'],                     // 파일 이름
      fileType: json['fileType'],                     // 파일 타입
      size: json['size'],                             // 파일 크기
      deletedAt: DateTime.parse(json['deletedAt']),   // 삭제 시각 (문자열 → DateTime 변환)
    );
  }
}
