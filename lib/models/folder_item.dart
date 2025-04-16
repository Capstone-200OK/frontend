import 'package:flutter_application_1/models/file_item.dart';


/// 폴더 정보 모델 (하위 폴더 + 파일들 포함)
class FolderItem {
  final int id;
  final String name;
  final bool isDeleted;
  final List<FileItem> files;
  final List<FolderItem> subFolders;

  FolderItem({
    required this.id,
    required this.name,
    required this.isDeleted,
    required this.files,
    required this.subFolders,
  });

  /// JSON -> FolderItem 객체로 변환 (재귀 구조 처리)
  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'],
      name: json['name'],
      isDeleted: json['isDeleted'],
      files: (json['files'] as List<dynamic>)
          .map((f) => FileItem.fromJson(f))
          .toList(),
      subFolders: (json['subFolders'] as List<dynamic>)
          .map((sf) => FolderItem.fromJson(sf))
          .toList(),
    );
  }
}