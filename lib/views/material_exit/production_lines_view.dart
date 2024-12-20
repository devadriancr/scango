import 'package:flutter/material.dart';

class ProductionLinesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Production Lines'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text('Production Lines Screen', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
