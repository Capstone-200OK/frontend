import 'package:flutter/material.dart';

// 파일 정보 클래스
class FileItem {
  final String name;
  final String type;
  final int sizeInBytes;
  bool isSelected;

  FileItem({
    required this.name,
    required this.type,
    required this.sizeInBytes,
    this.isSelected = false,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '${sizeInBytes}B';
    return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
  }
  
}