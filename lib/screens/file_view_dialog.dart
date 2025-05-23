import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 파일 미리보기 다이얼로그 위젯
class FilePreviewDialog extends StatelessWidget {
  final String fileUrl; // 파일 URL
  final String fileType; // 파일 확장자

  const FilePreviewDialog({
    super.key,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    Widget viewer;

    // 파일 타입에 따라 알맞은 뷰어 설정
    if (fileType == 'pdf') {
      viewer = SfPdfViewer.network(fileUrl); // PDF 뷰어
    } else if (["png", "jpg", "jpeg", "gif", "bmp"].contains(fileType)) {
      viewer = Image.network(fileUrl, fit: BoxFit.contain); // 이미지 뷰어
    } else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(fileType)) {
      viewer = OfficeViewerWindows(fileUrl: fileUrl); // 오피스 문서 뷰어 (윈도우 전용)
    } else if (["txt", "md", "csv"].contains(fileType)) {
      viewer = TextFileViewer(fileUrl: fileUrl); // 텍스트 파일 뷰어
    } 
    else {
      // 지원하지 않는 파일은 외부 앱으로 열기
      viewer = Center(
        child: TextButton(
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(fileUrl))) {
              launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
            }
          },
          child: const Text("미리보기를 지원하지 않는 파일입니다. 파일 열기"),
        ),
      );
    }

    // 다이얼로그로 뷰어 랜더링
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(width: 800, height: 600, child: viewer),
    );
  }
}
 
/// 윈도우용 Office 파일 뷰어 (WebView 기반)
class OfficeViewerWindows extends StatefulWidget {
  final String fileUrl;

  const OfficeViewerWindows({super.key, required this.fileUrl});

  @override
  State<OfficeViewerWindows> createState() => _OfficeViewerWindowsState();
}

class _OfficeViewerWindowsState extends State<OfficeViewerWindows> {
  final WebviewController _controller = WebviewController();
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView(); // 초기화 수행
  }

  // WebView 초기화 및 오피스 문서 뷰어 URL 로드
  Future<void> _initWebView() async {
    await _controller.initialize();
    final encoded = Uri.encodeFull(widget.fileUrl);
    final url = "https://view.officeapps.live.com/op/view.aspx?src=$encoded";

    await _controller.loadUrl(url);
    setState(() {
      _isWebViewReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isWebViewReady
        ? Webview(_controller) // 준비 완료 시 웹뷰 렌더링
        : const Center(child: CircularProgressIndicator()); // 로딩 중 표시
  }
}

/// 텍스트 파일(.txt, .md, .csv 등) 미리보기 위젯
class TextFileViewer extends StatelessWidget {
  final String fileUrl;

  const TextFileViewer({super.key, required this.fileUrl});

  // 텍스트 내용 비동기로 가져오기
  Future<String> _fetchTextContent() async {
    final response = await Uri.parse(fileUrl).resolveUri(Uri());
    final res = await http.get(response);
    if (res.statusCode == 200) {
      return utf8.decode(res.bodyBytes); // 한글 포함된 텍스트 대응
    } else {
      return '텍스트를 불러오지 못했습니다. 상태코드: ${res.statusCode}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchTextContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // 로딩 중
        } else if (snapshot.hasError) {
          return Center(child: Text("오류 발생: ${snapshot.error}")); // 에러 메시지
        } else {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: SelectableText(
                snapshot.data ?? '',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              ),
            ),
          );
        }
      },
    );
  }
}
