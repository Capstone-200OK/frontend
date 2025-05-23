import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

// 웹 기반으로 미리보기 위한 위젯 생성 함수
Widget createOfficeFileViewer(String fileUrl) {
  const viewId = 'office-viewer'; // 고유 뷰 ID 설정

  // URL을 인코딩하여 Office Online Viewer 형식의 URL 생성
  final encodedUrl = Uri.encodeFull(fileUrl);
  final officeViewUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encodedUrl';

  // iframe 요소 생성 및 스타일 설정
  final iframe = html.IFrameElement()
    ..src = officeViewUrl // 문서 URL 지정
    ..style.border = 'none' // 테두리 제거
    ..style.width = '100%' // 가로 전체
    ..style.height = '100%'; // 세로 전체

  // Flutter에서 HTML iframe을 렌더링할 수 있도록 view factory 등록
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) => iframe);

  // 등록한 iframe 뷰를 반환
  return const HtmlElementView(viewType: viewId);
}
