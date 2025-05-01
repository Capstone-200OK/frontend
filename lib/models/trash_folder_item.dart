class TrashFolderItem {
  final int trashId;
  final int folderId;
  final String folderName;
  final DateTime deletedAt;

  TrashFolderItem({
    required this.trashId,
    required this.folderId,
    required this.folderName,
    required this.deletedAt,
  });

  factory TrashFolderItem.fromJson(Map<String, dynamic> json) {
    return TrashFolderItem(
      trashId: json['trashId'],
      folderId: json['folderId'],
      folderName: json['folderName'],
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}
