import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FilePreviewDialog extends StatelessWidget {
  final String fileUrl;
  final String fileType;

  const FilePreviewDialog({
    super.key,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    Widget viewer;

    if (fileType == 'pdf') {
      viewer = SfPdfViewer.network(fileUrl);
    } else if (["png", "jpg", "jpeg", "gif", "bmp"].contains(fileType)) {
      viewer = Image.network(fileUrl, fit: BoxFit.contain);
    } else if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].contains(fileType)) {
      viewer = OfficeViewerWindows(fileUrl: fileUrl); // ✅ Windows 전용 WebView로
    } else if (["txt", "md", "csv"].contains(fileType)) {
      viewer = TextFileViewer(fileUrl: fileUrl);
    } 
    else {
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

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(width: 800, height: 600, child: viewer),
    );
  }
}

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
    _initWebView();
  }

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
        ? Webview(_controller)
        : const Center(child: CircularProgressIndicator());
  }
}

class TextFileViewer extends StatelessWidget {
  final String fileUrl;

  const TextFileViewer({super.key, required this.fileUrl});

  Future<String> _fetchTextContent() async {
    final response = await Uri.parse(fileUrl).resolveUri(Uri());
    final res = await http.get(response);
    if (res.statusCode == 200) {
      return utf8.decode(res.bodyBytes); // 한글 포함 대응
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("오류 발생: ${snapshot.error}"));
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
