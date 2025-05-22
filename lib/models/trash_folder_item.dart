/// 삭제된 폴더(휴지통) 정보를 담는 모델 클래스
class TrashFolderItem {
  final int trashId;           // 휴지통 항목 ID (고유 식별자)
  final int folderId;          // 원본 폴더 ID
  final String folderName;     // 폴더 이름
  final DateTime deletedAt;    // 삭제된 날짜 및 시간

  // 생성자
  TrashFolderItem({
    required this.trashId,
    required this.folderId,
    required this.folderName,
    required this.deletedAt,
  });

  // JSON 데이터를 TrashFolderItem 객체로 변환
  factory TrashFolderItem.fromJson(Map<String, dynamic> json) {
    return TrashFolderItem(
      trashId: json['trashId'],                         // 휴지통 ID
      folderId: json['folderId'],                       // 폴더 ID
      folderName: json['folderName'],                   // 폴더 이름
      deletedAt: DateTime.parse(json['deletedAt']),     // 삭제 시각 (문자열 → DateTime 변환)
    );
  }
}
