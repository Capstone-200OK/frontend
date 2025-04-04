import 'package:flutter/material.dart';

class FileManagerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  
    return Center( // 중앙 정렬
      child: Container(
        width: 1440, // 크기 축소
        height: 1040,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF263238)),
        child: Stack(
          children: [
            Positioned(
              left: 484, // 위치도 조정
              top: 657,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30, // 텍스트 크기도 줄이기
                  fontFamily: 'AppleSDGothicNeoEB00',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 22.10, // 비율 유지해서 축소
                ),
                child: Text('파일 관리를 자유롭게'),
              ),
            ),
            Positioned(
              left: 515,
              top: 260,
              child: Container(
                width: 450, // 이미지 크기 축소
                height: 450,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/LOGO.png"), // 내 이미지 파일 사용
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


