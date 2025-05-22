/// 중요 폴더 모델 클래스
class ImportantFolderItem {
  final int importantId; // 중요 문서함에 등록된 항목 ID
  final int folderId; // 원본 폴더 ID
  final String folderName; // 폴더 이름

  // 생성자
  ImportantFolderItem({
    required this.importantId,
    required this.folderId,
    required this.folderName,
  });

  // JSON 데이터를 ImportantFolderItem 객체로 변환
  factory ImportantFolderItem.fromJson(Map<String, dynamic> json) {
    return ImportantFolderItem(
      importantId: json['importantId'], // 중요 항목 ID
      folderId: json['folderId'], // 폴더 ID
      folderName: json['folderName'], // 폴더 이름
    );
  }
}
