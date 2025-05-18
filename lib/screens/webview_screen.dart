import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../services/connectivity_service.dart';

class AndroidServiceHelper {
  static const _channel = MethodChannel('media_service_channel');
  static Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {}
  }

  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {}
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  bool _isAdBlockEnabled = true;
  double _progress = 0.0;
  bool _canGoBack = false;
  String _statusText = 'Loading';
  String mainDomain = 'komikcast02.com';
  String mainUrl = 'https://komikcast02.com';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ConnectivityService.init(context);
    _loadSettings();
    AndroidServiceHelper.startForegroundService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.dispose();
    AndroidServiceHelper.stopForegroundService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      AndroidServiceHelper.stopForegroundService();
    }
    // Optionally, also stop on paused if you want to be extra safe:
    // if (state == AppLifecycleState.paused) {
    //   AndroidServiceHelper.stopForegroundService();
    // }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      mainDomain = prefs.getString('mainDomain') ?? 'komikcast02.com';
      mainUrl = prefs.getString('mainUrl') ?? 'https://komikcast02.com';
      _isAdBlockEnabled = prefs.getBool('adBlock') ?? true;
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  bool _isUrlAllowed(Uri uri) {
    return uri.host.contains(mainDomain);
  }

  void _showBlockedDialog(String url) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                _isDarkMode ? const Color(0xFF232634) : Colors.white,
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

  void _injectAdBlockJS() async {
    // Adblock: blokir elemen iklan umum tanpa mengganggu elemen utama/konten penting
    final String adBlockAdvanced = '''
      (function() {
        var adSelectors = [
          // Banner, sidebar, sticky, floating, popups
          '.adsbygoogle', '.ad-container', '.ad-banner', '.ad-slot', '.adbox', '.sponsored', '.popunder', '.popup', '.modal-backdrop',
          '.ads', '.adsbox', '.adarea', '.adunit', '.ad-footer', '.ad-header', '.ad-leaderboard', '.ad-rectangle', '.ad-skyscraper',
          '.ad-top', '.ad-bottom', '.ad-left', '.ad-right', '.ad-middle', '.ad-sidebar', '.ad-content', '.ad-label', '.ad-link',
          '.sticky-ad', '.floating-ad', '.fixed-ad', '.ad-float', '.ad-sticky', '.adblock', '.adclose', '.adclose-btn',
          '[id*="ads" i]', '[class*="ads" i]', '[id*="sponsor" i]', '[class*="sponsor" i]',
          '[id*="banner" i]', '[class*="banner" i]', '[id*="promot" i]', '[class*="promot" i]',
          '[data-ad]', '[data-ads]', '[data-google-query-id]', '[aria-label*="ads" i]', '[aria-label*="iklan" i]',
          // Iframe/script ad networks
          'iframe[src*="ads" i]:not([src*="speedtest.net" i])', 'iframe[src*="doubleclick" i]', 'iframe[src*="adservice" i]',
          'iframe[src*="googlesyndication" i]', 'iframe[src*="taboola" i]', 'iframe[src*="outbrain" i]',
          'script[src*="ad" i]', 'script[src*="doubleclick" i]', 'script[src*="googlesyndication" i]',
          // Overlay, modal, interstitial
          '.ad-modal', '.ad-interstitial', '.ad-overlay', '.adblocker-modal', '.adblocker-popup', '.adblocker',
          // Video overlay
          '.video-ads', '.ytp-ad-module', '.ytp-ad-overlay-container', '.ytp-ad-overlay-slot', '.ytp-ad-image-overlay',
        ];
        // Daftar selector yang tidak boleh dihapus (main content, header, gambar utama, dsb)
        var safeSelectors = [
          '.main-reading-area', '.reader-content', '.chapter-content', '.main-content', '.content', '.player', '.html5-video-player',
          '.video-stream', '.jw-player', '.vjs-tech', '.plyr', '.article', '.post', '.entry', '.container', '.body', '.page',
          '.primary', '.secondary', '.main', '.site-main', '.speedtest-container', '.result-container', '.main-content-wrapper',
          'header', 'nav', 'img', 'picture', 'figure', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'svg', 'canvas', 'video', 'audio',
          '#header', '#main-header', '#navbar', '#logo', '#content', '#main', '#root', '#readerarea', '#reader', '#chapter-content',
        ];
        function isSafeElement(el) {
          if (!el) return false;
          // Jika elemen atau parentnya mengandung selector penting, jangan blokir
          for (var i = 0; i < safeSelectors.length; i++) {
            try {
              if (el.matches(safeSelectors[i]) || (el.closest && el.closest(safeSelectors[i]))) {
                return true;
              }
            } catch (e) {}
          }
          // Jangan blokir gambar utama, header, nav, dsb
          if (["IMG","PICTURE","FIGURE","SVG","CANVAS","HEADER","NAV","VIDEO","AUDIO"].includes(el.tagName)) return true;
          return false;
        }
        function hideAds() {
          for (var i = 0; i < adSelectors.length; i++) {
            var sel = adSelectors[i];
            try {
              var elements = document.querySelectorAll(sel);
              for (var j = 0; j < elements.length; j++) {
                var el = elements[j];
                if (isSafeElement(el)) continue;
                el.style.setProperty('display', 'none', 'important');
                el.style.setProperty('visibility', 'hidden', 'important');
                el.style.setProperty('pointer-events', 'none', 'important');
                el.setAttribute('aria-hidden', 'true');
              }
            } catch (e) {}
          }
          // Remove overlay ads
          var overlays = document.querySelectorAll('[style*="z-index"]');
          for (var k = 0; k < overlays.length; k++) {
            var el = overlays[k];
            if (el.style && el.style.zIndex && parseInt(el.style.zIndex) > 1000) {
              if (isSafeElement(el) || (el.className && el.className.includes('player'))) continue;
              el.style.setProperty('display', 'none', 'important');
            }
          }
          // Remove ad scripts
          var scripts = document.querySelectorAll('script[src*="ad" i], script[src*="doubleclick" i], script[src*="googlesyndication" i], script[src*="taboola" i], script[src*="outbrain" i]');
          for (var l = 0; l < scripts.length; l++) {
            scripts[l].remove();
          }
        }
        hideAds();
        // MutationObserver untuk blokir iklan dinamis
        var observer = new MutationObserver(function() {
          hideAds();
        });
        observer.observe(document.body, { childList: true, subtree: true });
        // Blokir popup window
        window.open = function(url) { return null; };
        // Blokir link target _blank ke domain luar
        document.querySelectorAll('a[target="_blank"]').forEach(function(link) {
          if (!link.href.includes(window.location.hostname)) {
            link.addEventListener('click', function(e) {
              e.preventDefault();
            });
          } else {
            link.target = '_self';
          }
        });
      })();
    ''';
    await _controller?.evaluateJavascript(source: adBlockAdvanced);
  }

  void _injectPopupBlockerJS() async {
    // Block window.open and target _blank for non-mainDomain
    final popupBlockerJS = '''
      (function() {
        const mainDomain = "$mainDomain";
        window.open = function(url) {
          if (!url.includes(mainDomain)) {
            alert('Blocked popup to: ' + url);
            return null;
          }
          location.href = url;
          return null;
        };
        document.querySelectorAll('a[target="_blank"]').forEach(function(link) {
          if (!link.href.includes(mainDomain)) {
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
    await _controller?.evaluateJavascript(source: popupBlockerJS);
  }

  // void _showSettingsMenu() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final domainOnly = mainDomain;
  //   final urlController = TextEditingController(text: domainOnly);
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return _FuturisticSettingsPanel(
  //         urlController: urlController,
  //         onApplyUrl: (domain) async {
  //           domain = domain.trim().replaceAll(RegExp(r'^(https?://)'), '');
  //           if (domain.isEmpty || domain.contains('/') || domain.contains(' '))
  //             return;
  //           final url = 'https://$domain';
  //           await prefs.setString('mainDomain', domain);
  //           await prefs.setString('mainUrl', url);
  //           setState(() {
  //             mainDomain = domain;
  //             mainUrl = url;
  //           });
  //           _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  //           Navigator.of(context).pop();
  //         },
  //       );
  //     },
  //   );
  // }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor:
                    _isDarkMode ? const Color(0xFF232634) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text('Keluar Aplikasi'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        _isDarkMode
            ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF181A20),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF232634),
              ),
              textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
            )
            : ThemeData.light().copyWith(
              scaffoldBackgroundColor: const Color(0xFFF5F6FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF5F6FA),
              ),
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Roboto',
              ),
            );
    return Theme(
      data: theme,
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: _FuturisticNavbar(
              canGoBack: _canGoBack,
              onBack: () async {
                if (_controller != null && await _controller!.canGoBack()) {
                  _controller!.goBack();
                }
              },
              onReload: () async {
                await _controller?.reload();
              },
              adBlockEnabled: _isAdBlockEnabled,
              onToggleAdBlock: () async {
                setState(() {
                  _isAdBlockEnabled = !_isAdBlockEnabled;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('adBlock', _isAdBlockEnabled);
                if (_isAdBlockEnabled) {
                  _injectAdBlockJS();
                } else {
                  _controller?.reload();
                }
              },
              statusText: _statusText,
              progress:
                  _progress < 1.0 && _statusText != 'Complete'
                      ? _progress
                      : 1.0,
            ),
          ),
          body: Column(
            children: [
              ConnectivityService.networkStatusBar(mainDomain),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(mainUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    clearCache: false,
                    cacheEnabled: true,
                    userAgent:
                        "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
                    useWideViewPort: true,
                    allowContentAccess: true,
                    allowFileAccess: true,
                    builtInZoomControls: true,
                    supportMultipleWindows: true,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  shouldOverrideUrlLoading: (
                    controller,
                    navigationAction,
                  ) async {
                    final uri = navigationAction.request.url;
                    if (uri != null && !_isUrlAllowed(uri)) {
                      _showBlockedDialog(uri.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _progress = 0.0;
                      _statusText = 'Loading';
                    });
                    _updateCanGoBack();
                  },
                  onLoadStop: (controller, url) async {
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
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100.0;
                      _statusText = progress < 100 ? 'Loading' : 'Complete';
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCanGoBack() async {
    final canGoBack = await _controller?.canGoBack() ?? false;
    setState(() {
      _canGoBack = canGoBack;
    });
  }
}

class _FuturisticNavbar extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onReload;
  final bool adBlockEnabled;
  final VoidCallback onToggleAdBlock;
  final String statusText;
  final double progress;

  const _FuturisticNavbar({
    required this.canGoBack,
    required this.onBack,
    required this.onReload,
    required this.adBlockEnabled,
    required this.onToggleAdBlock,
    required this.statusText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF232634), Color(0xFF1A1C23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: canGoBack ? 1 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 26,
                      ),
                      color: canGoBack ? Colors.blueAccent : Colors.grey,
                      tooltip: 'Back',
                      onPressed: canGoBack ? onBack : null,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 26),
                    color: Colors.blueAccent,
                    tooltip: 'Reload',
                    onPressed: onReload,
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: onToggleAdBlock,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            adBlockEnabled
                                ? Colors.greenAccent.withOpacity(0.12)
                                : Colors.redAccent.withOpacity(0.12),
                        border: Border.all(
                          color:
                              adBlockEnabled
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color:
                                adBlockEnabled
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            adBlockEnabled ? 'AdBlock ON' : 'AdBlock OFF',
                            style: TextStyle(
                              color:
                                  adBlockEnabled
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Spacer sebelum statusText
                  const SizedBox(width: 18),
                  Expanded(
                    child: Center(
                      child: Text(
                        statusText == 'Complete' ? 'Done' : statusText,
                        style: TextStyle(
                          color:
                              statusText == 'Complete'
                                  ? Colors.greenAccent
                                  : Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          fontSize: 13,
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
                  // Spacer sebelum settings
                ],
              ),
              // Loading bar selalu di bawah dan full width
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.blueGrey.shade900,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.greenAccent : Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
