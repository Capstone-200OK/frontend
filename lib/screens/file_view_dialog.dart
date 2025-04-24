import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

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
    } else {
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
