import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewManager {
  late final WebViewController controller;
  final Function(String) onUrlChanged;
  final Function(String)? onLanguageChanged;
  final Function()? onPageLoaded;

  WebViewManager({
    required String initialUrl,
    required this.onUrlChanged,
    this.onLanguageChanged,
    this.onPageLoaded,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'LanguageChannel',
        onMessageReceived: (JavaScriptMessage message) {
          onLanguageChanged?.call(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},

          onPageStarted: (String url) {
            onUrlChanged(url);
          },

          onPageFinished: (String url) {
            onUrlChanged(url);
            _injectLanguageListener();
            // Notify that page is fully loaded
            onPageLoaded?.call();
          },

          onWebResourceError: (WebResourceError error) {},

          onNavigationRequest: (NavigationRequest request) {
            onUrlChanged(request.url);
            return _handleNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  /// INJECT JAVASCRIPT TO LISTEN FOR LANGUAGE CHANGES
  void _injectLanguageListener() {
    controller.runJavaScript('''
      (function() {
        // Store current language from URL
        const currentPath = window.location.pathname;
        const currentLang = currentPath.startsWith('/en') ? 'en' : 'id';
        
        // Listen for language change buttons - multiple selectors for robustness
        const languageSelectors = [
          '[data-language]',
          '[data-lang]', 
          '.language-toggle',
          '.lang-btn',
          '[class*="language"]',
          '[id*="language"]',
          'a:contains(EN)',
          'a:contains(ID)',
          'button:contains(EN)',
          'button:contains(ID)'
        ];
        
        // Try to find and listen to language buttons
        document.addEventListener('click', function(e) {
          const target = e.target.closest('[data-language], [data-lang], .language-toggle, .lang-btn, [class*="lang"]');
          if (target) {
            const lang = target.getAttribute('data-language') || 
                        target.getAttribute('data-lang') || 
                        target.getAttribute('lang') ||
                        target.textContent.toLowerCase().trim();
            if (lang && (lang.includes('en') || lang.includes('id') || lang === 'en' || lang === 'id')) {
              const finalLang = lang.toLowerCase().includes('en') ? 'en' : 'id';
              LanguageChannel.postMessage(finalLang);
            }
          }
        }, true);

        // Monitor URL changes via pushState and replaceState
        const originalPushState = window.history.pushState;
        const originalReplaceState = window.history.replaceState;
        
        window.history.pushState = function(...args) {
          const result = originalPushState.apply(this, args);
          detectAndNotifyLanguageChange();
          return result;
        };
        
        window.history.replaceState = function(...args) {
          const result = originalReplaceState.apply(this, args);
          detectAndNotifyLanguageChange();
          return result;
        };

        // Monitor popstate (back/forward buttons)
        window.addEventListener('popstate', function() {
          detectAndNotifyLanguageChange();
        });

        function detectAndNotifyLanguageChange() {
          const newPath = window.location.pathname;
          const newLang = newPath.startsWith('/en') ? 'en' : 'id';
          if (newLang !== currentLang) {
            LanguageChannel.postMessage(newLang);
          }
        }
      })();
    ''');
  }


  NavigationDecision _handleNavigation(String url) {
    final uri = Uri.parse(url);

    // Non-http scheme (tel:, mailto:, etc)
    if (!['http', 'https'].contains(uri.scheme)) {
      _launchExternal(uri);
      return NavigationDecision.prevent;
    }

    // External domains
    if (_isExternalDomain(uri.host)) {
      _launchExternal(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isExternalDomain(String host) {
    const externalDomains = [
      'facebook.com',
      'twitter.com',
      'x.com',
      'instagram.com',
      'linkedin.com',
      'maps.google.com',
      'google.com',
    ];

    return externalDomains.any((domain) => host.contains(domain));
  }

  Future<void> _launchExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $uri');
    }
  }
}
