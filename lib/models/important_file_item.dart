class ImportantFileItem {
  final int importantId;
  final int fileId;
  final String fileName;
  final String fileType;
  final int size;

  ImportantFileItem({
    required this.importantId,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.size,
  });

  factory ImportantFileItem.fromJson(Map<String, dynamic> json) {
    return ImportantFileItem(
      importantId: json['importantId'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      size: json['size'],
    );
  }
}
