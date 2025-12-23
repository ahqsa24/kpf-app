import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpf_app/webview_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WebViewController? _controller;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'url': 'https://kpf-dev.kp-futures.com/',
      'label': 'Beranda',
      'icon': FontAwesomeIcons.house, // fas fa-home
    },
    {
      'url': 'https://kpf-dev.kp-futures.com/profil/perusahaan',
      'label': 'Tentang',
      'icon': FontAwesomeIcons.book, // fas fa-book
    },
    {
      'url': 'https://kpf-dev.kp-futures.com/produk',
      'label': 'Produk',
      'icon': FontAwesomeIcons.layerGroup, // fas fa-layer-group
    },
    {
      'url': 'https://kpf-dev.kp-futures.com/prosedur/registrasi-online',
      'label': 'Prosedur',
      'icon': FontAwesomeIcons.map, // fas fa-map
    },
    {
      'url': 'https://kpf-dev.kp-futures.com/analisis/berita',
      'label': 'Berita',
      'icon': FontAwesomeIcons.newspaper, // fas fa-newspaper
    },
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _controller?.reload();
    } else {
      setState(() {
        _currentIndex = index;
      });
      _controller?.loadRequest(Uri.parse(_tabs[index]['url']));
    }
  }

  // Handle back button on Android
  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false; // Prevent closing app
    }
    return true; // Allow closing app
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: WebViewManager(
            initialUrl: _tabs[0]['url'], // Start with home
            onControllerCreated: (controller) {
              _controller = controller;
            },
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(
            0xFF00A63E,
          ), // androidTabBarBackgroundColor
          selectedItemColor: Colors.white, // androidTabBarIndicatorColor
          unselectedItemColor: const Color(
            0xFFE9ECEF,
          ), // androidTabBarTextColor
          showUnselectedLabels: true,
          items: _tabs.map((tab) {
            return BottomNavigationBarItem(
              icon: FaIcon(tab['icon'], size: 20),
              label: tab['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}
