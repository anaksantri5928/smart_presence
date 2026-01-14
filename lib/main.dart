import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absen Cerdas',
      theme: ThemeData(primarySwatch: Colors.red, fontFamily: 'Roboto'),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
