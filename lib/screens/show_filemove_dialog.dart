import 'package:flutter/material.dart';

// 파일 이동 내역을 팝업이 아닌 창 형태로 보여주는 함수
void showFileMoveDialog(
  BuildContext context,
  String fromPath,
  String toPath,
  String fileName, {
  List<Map<String, String>>? allHistories, // 전체 이동 기록 (옵션)
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0xFFECEFF1), // 배경색 지정
        title: const Text(
          '파일 이동 내역',
          style: TextStyle(fontSize: 22, fontFamily: 'APPLESDGOTHICNEOEB'),
        ),
        content: SizedBox(
          width: 400, // 창의 너비
          height: 250, // 창의 높이 (리스트 스크롤 가능)
          child: Scrollbar(
            // 스크롤바 표시
            child: ListView.builder(
              itemCount: allHistories?.length ?? 0, // 이동 기록 수
              itemBuilder: (context, index) {
                final history = allHistories![index];
                final prev = history['previousPath'] ?? ''; // 이전 경로
                final curr = history['currentPath'] ?? ''; // 현재 경로
                final name = history['fileName'] ?? ''; // 파일 이름

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 파일 이름 + 아이콘
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
                      // 이전 경로
                      Text(
                        '이전 경로: $prev',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'APPLESDGOTHICNEOR',
                        ),
                      ),
                      // 현재 경로
                      Text(
                        '현재 경로: $curr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'APPLESDGOTHICNEOR',
                        ),
                      ),
                      const Divider(), // 구분선
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          // 확인 버튼
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
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
          ),
        ],
      );
    },
  );
}
