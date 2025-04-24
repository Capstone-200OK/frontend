// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

Widget createOfficeFileViewer(String fileUrl) {
  const viewId = 'office-viewer';
  final encodedUrl = Uri.encodeFull(fileUrl);
  final officeViewUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encodedUrl';

  final iframe = html.IFrameElement()
    ..src = officeViewUrl
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) => iframe);

  return const HtmlElementView(viewType: viewId);
}
