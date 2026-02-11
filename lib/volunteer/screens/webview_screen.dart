import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String initialUrl;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF9F8F3))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _progress = progress);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFF9F8F3),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
              backgroundColor: const Color(0xFFEEF5F7),
              color: const Color(0xFF00A4DE),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
