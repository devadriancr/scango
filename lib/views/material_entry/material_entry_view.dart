import 'package:flutter/material.dart';

class MaterialEntryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material Entry'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text('Material Entry Screen', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

