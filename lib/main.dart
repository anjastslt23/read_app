import 'package:flutter/material.dart';
import 'screens/webview_screen.dart';

void main() {
  runApp(const MainApp());
}

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
        fontFamily: 'Roboto',
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(Colors.blue),
          trackColor: MaterialStateProperty.all(Colors.blueGrey),
        ),
      ),
      home: const WebViewScreen(),
    );
  }
}
