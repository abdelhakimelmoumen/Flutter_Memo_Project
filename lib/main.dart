// ignore_for_file: prefer_const_constructors
// Dev By Abdelhakim Elmoumen

import 'package:flutter/material.dart';
import 'package:smart_memo/screens/splash.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
