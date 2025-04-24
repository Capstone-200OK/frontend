//import 'package:flutter/material.dart';

/// 파일 정보 모델
class FileItem {
  final int id;
  final String name;
  final String? filePath ;
  final String type;
  final int sizeInBytes;
  bool isSelected;
  final String? fileUrl;
  final String? fileThumbnail;
  FileItem({
    this.id=0,
    required this.name,
    this.filePath,
    required this.type,
    required this.sizeInBytes,
    this.isSelected = false,
    this.fileUrl,
    this.fileThumbnail,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '${sizeInBytes}B';
    return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
  }

  /// JSON -> FileItem 객체로 변환
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      type: json['type'],
      sizeInBytes: json['sizeInBytes'],
      isSelected: json['isSelected'],
      fileUrl: json['fileUrl'],
    );
  }
}