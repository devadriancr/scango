import 'package:flutter/material.dart';

class ProductionLinesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();

    void _showNotification(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresaste: $message'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Línea de Producción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Escribe algo',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _showNotification(context, value);
                  _controller.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
