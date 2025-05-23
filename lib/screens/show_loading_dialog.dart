import 'package:flutter/material.dart';

// 로딩 다이얼로그를 표시하는 함수
Future<void> showLoadingDialog(BuildContext context) async {
  return showDialog(
    barrierDismissible: false, // 다이얼로그 외부를 터치해도 닫히지 않도록 설정
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white, // 배경색 흰색
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 둥근 모서리
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 20, // 너비 조절
                height: 20, // 높이 조절
                child: CircularProgressIndicator(
                  color: Color(0xFF455A64), // 로딩바 색상
                  strokeWidth: 3, // 로딩바 두께
                ),
              ),
              SizedBox(width: 20), // 아이콘과 텍스트 사이 간격
              // 안내 텍스트
              Text(
                "정리 중입니다...", // 사용자에게 진행 중임을 알림
                style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
