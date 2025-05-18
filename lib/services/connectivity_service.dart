import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static ConnectivityResult _connectionType = ConnectivityResult.none;
  static BuildContext? _context;
  static late final Stream<List<ConnectivityResult>> _stream;
  static late final StreamSubscription<List<ConnectivityResult>> _subscription;

  static void init(BuildContext context) {
    _context = context;
    _stream = Connectivity().onConnectivityChanged;
    _subscription = _stream.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (_context != null) {
        if (result != _connectionType) {
          _showFuturisticToast(_context!, result);
        }
        _connectionType = result;
      }
    });
  }

  static void dispose() {
    _subscription.cancel();
    _context = null;
  }

  static Widget networkStatusBar(String mainDomain) {
    IconData icon;
    Color color;
    String label;
    if (_connectionType == ConnectivityResult.wifi) {
      icon = Icons.wifi;
      color = Colors.cyanAccent;
      label = 'WiFi';
    } else if (_connectionType == ConnectivityResult.mobile) {
      icon = Icons.signal_cellular_alt;
      color = Colors.purpleAccent;
      label = 'Mobile Data';
    } else {
      icon = Icons.signal_wifi_off;
      color = Colors.redAccent;
      label = 'Offline';
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFF232634),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Currently accessing: $mainDomain',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static void _showFuturisticToast(
    BuildContext context,
    ConnectivityResult type,
  ) {
    String text = 'Network changed';
    IconData icon = Icons.device_unknown;
    Color color = Colors.blueAccent;
    if (type == ConnectivityResult.wifi) {
      text = 'Connected to WiFi';
      icon = Icons.wifi;
      color = Colors.cyanAccent;
    } else if (type == ConnectivityResult.mobile) {
      text = 'Connected to Mobile Data';
      icon = Icons.signal_cellular_alt;
      color = Colors.purpleAccent;
    } else {
      text = 'No Internet Connection';
      icon = Icons.signal_wifi_off;
      color = Colors.redAccent;
    }
    final toast = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.1,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black54,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      duration: const Duration(seconds: 2),
      elevation: 10,
    );
    ScaffoldMessenger.of(context).showSnackBar(toast);
  }
}
