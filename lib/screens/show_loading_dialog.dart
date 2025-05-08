import 'package:flutter/material.dart';

Future<void> showLoadingDialog(BuildContext context) async {
  return showDialog(
    barrierDismissible: false, // 바깥 터치로 닫히지 않도록
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 20, // 너비 조절
                height: 20, // 높이 조절
                child: CircularProgressIndicator(
                  color: Color(0xFF455A64),
                  strokeWidth: 3, // 로딩 바 두께
                ),
              ),
              SizedBox(width: 20),
              Text(
                "정리 중입니다...",
                style: TextStyle(fontSize: 16, fontFamily: 'APPLESDGOTHICNEOR'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
