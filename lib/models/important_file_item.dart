/// 중요 파일 모델 클래스
class ImportantFileItem {
  final int importantId;      // 중요 문서함에 등록된 항목 ID
  final int fileId;           // 원본 파일 ID
  final String fileName;      // 파일 이름
  final String fileType;      // 파일 타입 (예: pdf, jpg 등)
  final int size;             // 파일 크기 (바이트 단위)
  final String fileUrl;       // 파일 접근 URL
  final String fileThumbnail; // 파일 썸네일 URL

  // 생성자
  ImportantFileItem({
    required this.importantId,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.size,
    required this.fileUrl,
    required this.fileThumbnail,
  });

  // JSON 데이터를 ImportantFileItem 객체로 변환
  factory ImportantFileItem.fromJson(Map<String, dynamic> json) {
    return ImportantFileItem(
      importantId: json['importantId'], // 중요 항목 ID
      fileId: json['fileId'], // 파일 ID
      fileName: json['fileName'], // 파일 이름
      fileType: json['fileType'], // 파일 타입
      size: json['size'], // 파일 크기
      fileUrl: json['fileUrl'], // 파일 URL
      fileThumbnail: json['fileThumbnailUrl'] // 썸네일 URL
    );
  }
}
