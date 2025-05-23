import 'package:flutter/material.dart';

class FileManagerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  
    return Center( // 화면 중앙에 배치
      child: Container(
        width: 1440, // 전체 컨테이너 너비
        height: 1040, // 전체 컨테이너 높이
        clipBehavior: Clip.antiAlias, // 넘치는 부분 잘라냄
        decoration: BoxDecoration(color: const Color(0xFF263238)), // 배경색: 어두운 남색 계열
        child: Stack(
          children: [
            // 텍스트 위치 조정
            Positioned(
              left: 484, // 왼쪽에서의 위치
              top: 657, // 위에서의 위치
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.white, // 흰색 텍스트
                  fontSize: 30, // 텍스트 크기도 축소
                  fontFamily: 'AppleSDGothicNeoEB00', // 지정된 폰트
                  fontWeight: FontWeight.w400, // 보통 두께
                  letterSpacing: 22.10, // 글자 간격 조절
                ),
                child: Text('파일 관리를 자유롭게'), // 표시할 텍스트
              ),
            ),
            // 로고 이미지 위치 조정 및 표시
            Positioned(
              left: 515, // 왼쪽에서의 위치
              top: 260, // 위에서의 위치
              child: Container(
                width: 450, // 이미지 너비
                height: 450, // 이미지 높이
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/LOGO.png"), // 로컬 이미지 파일 경로
                    fit: BoxFit.fill, // 이미지가 영역에 맞게 채워지도록 설정
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

