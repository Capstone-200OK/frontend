class ImportantFileItem {
  final int importantId;
  final int fileId;
  final String fileName;
  final String fileType;
  final int size;
  final String fileUrl;
  final String fileThumbnail;
  ImportantFileItem({
    required this.importantId,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.size,
    required this.fileUrl,
    required this.fileThumbnail,
  });

  factory ImportantFileItem.fromJson(Map<String, dynamic> json) {
    return ImportantFileItem(
      importantId: json['importantId'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      size: json['size'],
      fileUrl: json['fileUrl'],
      fileThumbnail: json['fileThumbnailUrl']
    );
  }
}
