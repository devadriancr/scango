import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExternalStorageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('External Storage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen SVG
            SvgPicture.asset(
              'assets/images/maintenance.svg',
              width: 300, // Ajusta el tamaño según sea necesario
              height: 300,
            ),
            const SizedBox(height: 20), // Espaciado entre imagen y texto

            // Mensaje de mantenimiento
            const Text(
              'Esta sección está en mantenimiento.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
