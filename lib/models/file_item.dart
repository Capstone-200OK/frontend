/// 파일 정보 모델 클래스
class FileItem {
  final int id; // 파일 ID
  final String name; // 파일 이름
  final String? filePath; // 파일 경로 (nullable)
  final String type; // 파일 타입 (예: pdf, jpg 등)
  final int sizeInBytes; // 파일 크기 (바이트 단위)
  bool isSelected; // 선택 여부 (체크박스 등에서 사용)
  final String? fileUrl; // 파일 URL (nullable)
  final String? fileThumbnail; // 파일 썸네일 URL (nullable)
  bool isFavorite; // 중요 표시 여부 (즐겨찾기)

  // 생성자
  FileItem({
    this.id = 0,
    required this.name,
    this.filePath,
    required this.type,
    required this.sizeInBytes,
    this.isSelected = false,
    this.fileUrl,
    this.fileThumbnail,
    this.isFavorite = false,
  });

  // 파일 크기를 보기 좋게 변환 (예: 1234 -> 1.2KB)
  String get sizeFormatted {
    if (sizeInBytes < 1024) return '${sizeInBytes}B';
    return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
  }

  // JSON 데이터를 FileItem 객체로 변환하는 팩토리 생성자
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'], // 파일 ID
      name: json['name'], // 파일 이름
      filePath: json['filePath'], // 파일 경로
      type: json['type'], // 파일 타입
      sizeInBytes: json['sizeInBytes'], // 파일 크기
      isSelected: json['isSelected'], // 선택 상태
      fileUrl: json['fileUrl'], // 파일 URL
      isFavorite: json['isFavorite'] ?? false, // 중요 여부 (기본값 false)
    );
  }
}
