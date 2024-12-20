import 'package:flutter/material.dart';
import 'package:scango/views/home_view.dart';

void main() {
  runApp(ScangoApp());
}

class ScangoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scango',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeView(),
    );
  }
}
