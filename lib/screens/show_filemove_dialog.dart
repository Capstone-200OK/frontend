//팝업이 아니라 창으로 만들기
//리스트 스크롤 할 수 있게끔

import 'package:flutter/material.dart';

void showFileMoveDialog(
  BuildContext context,
  String fromPath,
  String toPath,
  String fileName, {
  List<Map<String, String>>? allHistories, // 전체 목록도 옵션으로 받기
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xFFECEFF1),
        title: const Text(
          '파일 이동 내역',
          style: TextStyle(fontSize: 22, fontFamily: 'APPLESDGOTHICNEOEB'),
        ),
        content: SizedBox(
          width: 400,
          height: 250, // 원하는 높이 조정 가능
          child: Scrollbar(
            child: ListView.builder(
              itemCount: allHistories?.length ?? 0,
              itemBuilder: (context, index) {
                final history = allHistories![index];
                final prev = history['previousPath'] ?? '';
                final curr = history['currentPath'] ?? '';
                final name = history['fileName'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            size: 16,
                            color: Color(0xFF455A64),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'APPLESDGOTHICNEOEB',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '이전 경로: $prev',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'APPLESDGOTHICNEOR',
                        ),
                      ),
                      Text(
                        '현재 경로: $curr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'APPLESDGOTHICNEOR',
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'APPLESDGOTHICNEOEB',
                color: Color(0xFF2E24E0),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
