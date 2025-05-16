// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MainApp());
}

/// MainApp is the root widget of the application.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komikcast Viewer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF181A20),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF232634),
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(Colors.blue),
          trackColor: MaterialStateProperty.all(Colors.blueGrey),
        ),
      ),
      home: const WebViewScreen(),
    );
  }
}

/// WebViewScreen is a stateful widget that displays the webview and settings.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isAdBlockEnabled = true;
  double _progress = 0.0;
  bool _canGoBack = false;
  String _statusText = 'Loading';

  // The main website domain to allow navigation within.
  final String mainDomain = 'komikcast02.com';

  @override
  void initState() {
    super.initState();
    // Hybrid composition is enabled by default in recent webview_flutter versions.
    // No need to set WebView.platform manually.

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setUserAgent(
            "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
          )
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                // Block navigation to URLs outside the main domain.
                Uri uri = Uri.parse(request.url);
                if (!_isUrlAllowed(uri)) {
                  _showBlockedDialog(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageStarted: (url) {
                setState(() {
                  _progress = 0.0;
                  _statusText = 'Loading';
                });
                _updateCanGoBack();
              },
              onPageFinished: (url) {
                setState(() {
                  _progress = 1.0;
                  _statusText = 'Complete';
                });
                if (_isAdBlockEnabled) {
                  _injectAdBlockJS();
                }
                _injectPopupBlockerJS();
                _updateCanGoBack();
              },
              onProgress: (progress) {
                setState(() {
                  _progress = progress / 100.0;
                  _statusText = progress < 100 ? 'Loading' : 'Complete';
                });
              },
            ),
          )
          ..loadRequest(Uri.parse('https://komikcast02.com'));
  }

  /// Checks if the URL is allowed to be loaded (within main domain).
  bool _isUrlAllowed(Uri uri) {
    return uri.host.contains(mainDomain);
  }

  /// Shows an alert dialog when navigation is blocked.
  void _showBlockedDialog(String url) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Navigation Blocked'),
            content: Text('Navigation to external URL blocked:\n$url'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Injects JavaScript to remove common ad elements from the page.
  void _injectAdBlockJS() {
    final adBlockJS = '''
      // Hapus elemen iklan, tapi jangan hapus gambar komik
      function safeRemove(selector) {
        document.querySelectorAll(selector).forEach(function(el) {
          // Jangan hapus gambar komik utama
          if (el && el.closest && el.closest('.chapter-image, .main-reading-area, .reader-area, .reader-content, .reader-content img, .chapter-content img')) return;
          // Cek apakah el ada sebelum akses style
          if (el && el.style && typeof el.style.zIndex !== 'undefined' && el.style.zIndex > 1000) return;
          el && el.remove && el.remove();
        });
      }
      const adSelectors = [
        '[id*="ad"]:not([id*="read"]):not([id*="header"]):not([id*="footer"])',
        '[class*="ad"]:not([class*="read"]):not([class*="header"]):not([class*="footer"])',
        '[class*="ads"]',
        '[class*="banner"]',
        '[class*="pop"]',
        '[class*="sponsor"]',
        'iframe[src*="ads"]',
        'iframe[src*="doubleclick"]',
        'iframe[src*="adservice"]',
        'div[data-ad]',
        'div[data-google-query-id]',
        'script[src*="ad"]',
        '.adsbygoogle',
        '.ad-container',
        '.ad-banner',
        '.ad-slot',
        '.adbox',
        '.sponsored',
        '.popunder',
        '.popup',
        '.modal-backdrop',
      ];
      adSelectors.forEach(safeRemove);
      // Coba ulangi setelah 2 detik untuk iklan yang muncul belakangan
      setTimeout(() => { adSelectors.forEach(safeRemove); }, 2000);
      // Perbaikan error login: jangan akses style jika el null
      document.querySelectorAll('[style*="z-index"]').forEach(function(el) {
        if (el && el.style && typeof el.style.zIndex !== 'undefined' && el.style.zIndex > 1000) return;
      });
    ''';
    _controller.runJavaScript(adBlockJS);
  }

  /// Injects JavaScript to block popups and new tabs from unrelated links.
  void _injectPopupBlockerJS() {
    final popupBlockerJS = '''
      // Intercept window.open and target="_blank" links
      (function() {
        window.open = function(url) {
          if (!url.includes("$mainDomain")) {
            alert('Blocked popup to: ' + url);
            return null;
          }
          location.href = url;
          return null;
        };
        document.querySelectorAll('a[target="_blank"]').forEach(function(link) {
          if (!link.href.includes("$mainDomain")) {
            link.addEventListener('click', function(e) {
              e.preventDefault();
              alert('Blocked external link: ' + link.href);
            });
          } else {
            link.target = '_self';
          }
        });
      })();
    ''';
    _controller.runJavaScript(popupBlockerJS);
  }

  /// Toggles the ad-block feature on or off.
  void _toggleAdBlock(bool value) {
    setState(() {
      _isAdBlockEnabled = value;
    });
    if (_isAdBlockEnabled) {
      _injectAdBlockJS();
    } else {
      // Reload page to remove injected ad-block effects.
      _controller.reload();
    }
  }

  void _updateCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    setState(() {
      _canGoBack = canGoBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF232634), Color(0xFF1A1C23)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _canGoBack ? Colors.blue : Colors.grey,
                  ),
                  tooltip: 'Back',
                  onPressed:
                      _canGoBack
                          ? () async {
                            if (await _controller.canGoBack()) {
                              _controller.goBack();
                            }
                          }
                          : null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                  tooltip: 'Reload',
                  onPressed: () async {
                    await _controller.reload();
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            _progress < 1.0 && _statusText != 'Complete'
                                ? _progress
                                : 1.0,
                        minHeight: 6,
                        backgroundColor: Colors.blueGrey.shade900,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _statusText == 'Complete'
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusText),
                      style: TextStyle(
                        color:
                            _statusText == 'Complete'
                                ? Colors.greenAccent
                                : Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _showSettingsMenu,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  /// Shows the settings menu with ad-block toggle.
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Enable Ad-Block'),
                value: _isAdBlockEnabled,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  _toggleAdBlock(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
