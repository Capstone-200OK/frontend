class TrashFileItem {
  final int trashId;
  final int fileId;
  final String fileName;
  final String fileType;
  final int size;
  final DateTime deletedAt;

  TrashFileItem({
    required this.trashId,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.size,
    required this.deletedAt,
  });

  factory TrashFileItem.fromJson(Map<String, dynamic> json) {
    return TrashFileItem(
      trashId: json['trashId'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      size: json['size'],
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}
