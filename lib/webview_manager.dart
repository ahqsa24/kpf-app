import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewManager extends StatefulWidget {
  final String initialUrl;
  final Function(WebViewController) onControllerCreated;

  const WebViewManager({
    super.key,
    required this.initialUrl,
    required this.onControllerCreated,
  });

  @override
  State<WebViewManager> createState() => _WebViewManagerState();
}

class _WebViewManagerState extends State<WebViewManager> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
             if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
      
    widget.onControllerCreated(_controller);
  }

  Future<NavigationDecision> _handleNavigation(String url) async {
    final uri = Uri.parse(url);
    
    // Handle non-http schemes (tel, mailto, whatsapp, etc.)
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return NavigationDecision.prevent;
      }
    }

    // Specific external domains logic (based on appConfig.json)
    if (_isExternalLink(url)) {
       if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      }
    }

    return NavigationDecision.navigate;
  }

  bool _isExternalLink(String url) {
    // Logic from appConfig.json
    final externalPatterns = [
      RegExp(r'https?://([-\w]+\.)*facebook\.com.*'),
      RegExp(r'https?://([-\w]+\.)*(twitter|x)\.com/.*'),
      RegExp(r'https?://([-\w]+\.)*instagram\.com/.*'),
      RegExp(r'https?://maps\.google\.com.*'),
      RegExp(r'https?://([-\w]+\.)*google\.com/maps/search/.*'),
      RegExp(r'https?://([-\w]+\.)*linkedin\.com/.*'),
    ];

    for (final pattern in externalPatterns) {
      if (pattern.hasMatch(url)) {
        return true;
      }
    }
    
    // Also check if it's NOT our domain if we want to be strict,
    // but appConfig says "All Other Links" -> "appbrowser" (external), 
    // and "kp-futures.com" -> internal.
    if (!url.contains('kp-futures.com')) {
        // Decide if we want to open ALL other links externally.
        // For now, let's keep it inside unless matched above purely or clearly external content.
        // Actually, config says: "regex": ".*", "mode": "appbrowser" (All Other Links).
        // So if it's not kp-futures.com, it should likely be external.
        return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF009688), // Android Accent Color from config
            ),
          ),
      ],
    );
  }
}
