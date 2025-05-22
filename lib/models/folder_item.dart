import 'package:flutter_application_1/models/file_item.dart';

/// 폴더 정보 모델 클래스
// 하위 폴더 및 파일 리스트를 포함하는 재귀 구조
class FolderItem {
  final int id; // 폴더 ID
  final String name; // 폴더 이름
  final bool ?isDeleted; // 삭제 여부 (nullable)
  final List<FileItem>? files; // 폴더에 포함된 파일 목록
  final List<FolderItem>? subFolders; // 폴더에 포함된 하위 폴더 목록

  // 생성자
  FolderItem({
    required this.id,
    required this.name,
     this.isDeleted,
     this.files,
     this.subFolders,
  });

  // JSON 데이터를 FolderItem 객체로 변환 (하위 폴더 포함 재귀적으로 처리)
  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'], // 폴더 ID
      name: json['name'], // 폴더 이름
      isDeleted: json['isDeleted'], // 삭제 여부
      files: (json['files'] as List<dynamic>)
          .map((f) => FileItem.fromJson(f)) // 파일 목록 변환
          .toList(),
      subFolders: (json['subFolders'] as List<dynamic>)
          .map((sf) => FolderItem.fromJson(sf)) // 하위 폴더 목록도 재귀적으로 변환
          .toList(),
    );
  }
}