import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpf_app/webview_manager.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { id, en }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewManager _webViewManager;
  late final WebViewController _controller;

  int _currentIndex = 0;
  AppLanguage _currentLanguage = AppLanguage.id;
  bool _isUpdating = false;
  bool _isWebViewLoaded = false;

  static const String baseUrl = 'https://kpf-dev.kp-futures.com';

  final Map<AppLanguage, Map<String, String>> _dialogText = {
    AppLanguage.id: {
      'title': 'Pembaruan Tersedia',
      'message': 'Versi terbaru aplikasi tersedia. Instal sekarang untuk mendapatkan fitur terbaru dan perbaikan bug.',
      'installNow': 'Instal Sekarang',
      'later': 'Nanti',
    },
    AppLanguage.en: {
      'title': 'Update Available',
      'message': 'A new version of the app is available. Install now to get the latest features and bug fixes.',
      'installNow': 'Install Now',
      'later': 'Later',
    },
  };

  final List<Map<String, dynamic>> _tabs = [
    {
      'path': '/',
      'label': {AppLanguage.id: 'Beranda', AppLanguage.en: 'Home'},
      'icon': FontAwesomeIcons.house,
    },
    {
      'path': '/profil/perusahaan',
      'label': {AppLanguage.id: 'Tentang', AppLanguage.en: 'About'},
      'icon': FontAwesomeIcons.book,
    },
    {
      'path': '/produk',
      'label': {AppLanguage.id: 'Produk', AppLanguage.en: 'Products'},
      'icon': FontAwesomeIcons.layerGroup,
    },
    {
      'path': '/prosedur/registrasi-online',
      'label': {AppLanguage.id: 'Prosedur', AppLanguage.en: 'Procedure'},
      'icon': FontAwesomeIcons.map,
    },
    {
      'path': '/analisis/berita',
      'label': {AppLanguage.id: 'Berita', AppLanguage.en: 'News'},
      'icon': FontAwesomeIcons.newspaper,
    },
  ];

    @override
    void initState() {
      super.initState();
      _webViewManager = WebViewManager(
        initialUrl: baseUrl,
        onUrlChanged: _syncTabAndLanguageFromUrl,
        onLanguageChanged: _handleLanguageChangeFromWebView,
        onPageLoaded: _handlePageLoaded,
      );
      _controller = _webViewManager.controller;
      
      // Check for Shorebird patch updates
      _checkForUpdates();
    }

  void _handlePageLoaded() {
    setState(() {
      _isWebViewLoaded = true;
    });
    debugPrint('WebView page loaded');
  }

  Future<void> _checkForUpdates() async {
    try {
      final updater = ShorebirdUpdater();
      if (!updater.isAvailable) {
        return;
      }
      
      final status = await updater.checkForUpdate();
      if (status == UpdateStatus.outdated && mounted) {
        // Get the AVAILABLE patch to use as version identifier
        final nextPatch = await updater.readNextPatch();
        final availableVersion = nextPatch?.number.toString() ?? 'unknown';
        
        debugPrint('Available patch: $availableVersion, Status: $status');
        
        // Check if user already skipped this update
        final prefs = await SharedPreferences.getInstance();
        final skippedVersion = prefs.getString('skipped_update_version');
        
        debugPrint('Skipped version: $skippedVersion');
        
        // Only show dialog if this is a new update (different version)
        if (skippedVersion != availableVersion) {
          _showUpdateDialog();
        } else {
          debugPrint('Update already skipped or installed for version: $availableVersion');
        }
      } else {
        debugPrint('No updates available. Status: $status');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog() {
    final texts = _dialogText[_currentLanguage]!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(texts['title']!),
              content: _isUpdating
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00A63E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentLanguage == AppLanguage.id
                              ? 'Menginstal pembaruan...'
                              : 'Installing update...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Text(texts['message']!),
              actions: _isUpdating
                  ? []
                  : [
                      TextButton(
                        onPressed: () async {
                          // Save that user skipped this update
                          try {
                            final updater = ShorebirdUpdater();
                            final nextPatch = await updater.readNextPatch();
                            final availableVersion = nextPatch?.number.toString() ?? 'unknown';
                            
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('skipped_update_version', availableVersion);
                            debugPrint('Saved skipped update version: $availableVersion');
                          } catch (e) {
                            debugPrint('Error saving skipped update: $e');
                          }
                          
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          texts['later']!,
                          style: const TextStyle(color: Color(0xFF757575)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setDialogState(() {
                            _isUpdating = true;
                          });
                          
                          // Close dialog and show loading overlay
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                          
                          // Show loading overlay while installing
                          _showLoadingOverlay(
                            _currentLanguage == AppLanguage.id
                                ? 'Mengunduh dan memasang pembaruan...\nJangan tutup aplikasi.'
                                : 'Downloading and installing update...\nDo not close the app.',
                          );
                          
                          await _installUpdate();
                          // App will restart after update, so we don't pop here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A63E),
                        ),
                        child: Text(
                          texts['installNow']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _installUpdate() async {
    try {
      final updater = ShorebirdUpdater();
      debugPrint('Updater available: ${updater.isAvailable}');
      
      if (!updater.isAvailable) {
        throw Exception('Shorebird updater is not available on this platform');
      }

      debugPrint('Starting update download and install...');
      
      // Call the update method which handles everything
      await updater.update();
      
      // If update is successful, the app will restart automatically
      debugPrint('Update completed, app will restart');
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Error installing update: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Handle "No update" error - patch sudah scheduled untuk install
      if (errorMessage.contains('noUpdate') || errorMessage.contains('No update')) {
        debugPrint('Patch akan diinstall saat restart aplikasi...');
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show success notification - user dapat continue menggunakan app
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _currentLanguage == AppLanguage.id
                    ? 'Pembaruan berhasil diunduh, silahkan restart aplikasi untuk menerapkan'
                    : 'Update downloaded successfully, please restart the app to apply',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF00A63E),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          setState(() {
            _isUpdating = false;
          });
        }
        return;
      }
      
      setState(() {
        _isUpdating = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentLanguage == AppLanguage.id
                  ? 'Gagal menginstal pembaruan: ${e.toString()}'
                  : 'Failed to install update: ${e.toString()}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showLoadingOverlay(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF00A63E),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLanguageChangeFromWebView(String language) {
    final newLanguage = language.toLowerCase().contains('en') ? AppLanguage.en : AppLanguage.id;
    
    if (_currentLanguage != newLanguage) {
      setState(() {
        _currentLanguage = newLanguage;
      });
      // Reload the current tab with the new language
      _reloadCurrentTabWithLanguage(newLanguage);
    }
  }

  void _reloadCurrentTabWithLanguage(AppLanguage language) {
    final path = _tabs[_currentIndex]['path'];
    final langPrefix = language == AppLanguage.en ? '/en' : '';
    final url = '$baseUrl$langPrefix$path';
    _webViewManager.controller.loadRequest(Uri.parse(url));
  }

  void _syncTabAndLanguageFromUrl(String url) {
    final uri = Uri.parse(url);
    String path = uri.path;

    final isEnglish = path.startsWith('/en');
    final newLanguage = isEnglish ? AppLanguage.en : AppLanguage.id;

    if (_currentLanguage != newLanguage) {
      setState(() {
        _currentLanguage = newLanguage;
      });
    }

    // ===== NORMALISASI PATH =====
    if (isEnglish) {
      path = path.replaceFirst('/en', '');
      if (path.isEmpty) path = '/';
    }

    // ===== SYNC TAB =====
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i]['path'] == path && _currentIndex != i) {
        setState(() {
          _currentIndex = i;
        });
        break;
      }
    }
  }

   void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _isWebViewLoaded = false; // Reset loading state
    });

    final path = _tabs[index]['path'];
    final langPrefix = _currentLanguage == AppLanguage.en ? '/en' : '';

    final url = '$baseUrl$langPrefix$path';
    _webViewManager.controller.loadRequest(Uri.parse(url));
  }

  Future<bool> _onWillPop() async {
    if (await _webViewManager.controller.canGoBack()) {
      _webViewManager.controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(
                controller: _webViewManager.controller,
              ),
              // Show loading overlay if WebView not yet loaded or updating
              if (!_isWebViewLoaded || _isUpdating)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00A63E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentLanguage == AppLanguage.id
                              ? 'Memuat aplikasi...'
                              : 'Loading app...',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(
            0xFF00A63E,
          ),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white38, // androidTabBarTextColor
          showUnselectedLabels: true,
          items: _tabs.map((tab) {
            return BottomNavigationBarItem(
              icon: FaIcon(tab['icon'], size: 20),
              label: tab['label'][_currentLanguage],
            );
          }).toList(),
        ),
      ),
    );
  }
}
