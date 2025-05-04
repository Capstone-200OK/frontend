class ImportantFolderItem {
  final int importantId;
  final int folderId;
  final String folderName;

  ImportantFolderItem({
    required this.importantId,
    required this.folderId,
    required this.folderName,
  });

  factory ImportantFolderItem.fromJson(Map<String, dynamic> json) {
    return ImportantFolderItem(
      importantId: json['importantId'],
      folderId: json['folderId'],
      folderName: json['folderName'],
    );
  }
}
