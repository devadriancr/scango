import 'package:flutter/material.dart';
// import 'package:scango/views/material_entry/material_entry_view.dart';
import 'package:scango/views/material_entry/container_list_view.dart';
import 'package:scango/views/material_exit/material_exit_view.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple, // Color actualizado
        title: Text(
          'SCANGO',
          style: TextStyle(
            fontWeight: FontWeight.w600, // Semibold
            fontSize: 20, // Tamaño de la fuente
            letterSpacing: 1.5, // Espaciado entre letras (para mayúsculas)
            color: Colors.white, // Letras blancas
          ),
        ),
        centerTitle: true, // Centrar el texto
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContainerListView(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entrada de Material',
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Icons.warehouse_outlined, size: 30),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaterialExitView(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salida de Material',
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Icons.local_shipping_outlined, size: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
