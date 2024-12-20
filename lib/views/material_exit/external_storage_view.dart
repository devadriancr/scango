import 'package:flutter/material.dart';

class ExternalStorageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('External Storage'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text('External Storage Screen', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
