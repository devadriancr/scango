import 'package:flutter/material.dart';
import 'package:scango/services/database_service.dart';

class ProductionLinesView extends StatefulWidget {
  @override
  _ProductionLinesViewState createState() => _ProductionLinesViewState();
}

class _ProductionLinesViewState extends State<ProductionLinesView> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _dbService.initializeDatabase();
    _loadMaterials(); // Cargar datos al iniciar
  }

  void _loadMaterials() async {
    final materials =
        await _dbService.getActiveMaterialExits(); // Ahora sin parámetro
    setState(() {
      _materials = materials;
    });
  }

  void _processInput(String input) async {
    input = input.trim();

    if (input.length >= 30 && input.length <= 35) {
      String code = input.toUpperCase();
      String noOrder = code.substring(0, 7);
      String serial = code.substring(0, 10);
      String partNo = code.substring(10, 20);
      int partQty = int.tryParse(code.substring(20, 26)) ?? 0;
      String supplier = code.substring(26, 31);

      // Verificar si el material ya está registrado como salida
      bool isRegistered = await _dbService.isMaterialExitRegistered(
        supplier: supplier,
        serial: serial,
        partNo: partNo,
        partQty: partQty,
        noOrder: noOrder,
      );

      if (isRegistered) {
        _showNotification('Este material ya está registrado como salida.',
            isError: true);
      } else {
        await _dbService.addMaterialExit(
          supplier: supplier,
          serial: serial,
          partNo: partNo,
          partQty: partQty,
          noOrder: noOrder,
        );

        _showNotification('Salida registrada correctamente.');
        _loadMaterials(); // Recargar datos
      }
    } else if (input.length >= 159) {
      String dataRequest = input.toUpperCase();
      List<String> dataParts = dataRequest.split(',');

      int partQty = int.tryParse(dataParts[10]) ?? 0;
      String supplier = dataParts[11];
      String serial = dataParts[13];
      String partNo = dataParts.last;

      // Verificar si el material ya está registrado como salida
      bool isRegistered = await _dbService.isMaterialExitRegistered(
        supplier: supplier,
        serial: serial,
        partNo: partNo,
        partQty: partQty,
        noOrder: dataParts[9], // Usar noOrder de la data
      );

      if (isRegistered) {
        _showNotification('Este material ya está registrado como salida.',
            isError: true);
      } else {
        await _dbService.addMaterialExit(
          supplier: supplier,
          serial: serial,
          partNo: partNo,
          partQty: partQty,
        );

        _showNotification('Salida registrada correctamente.');
        _loadMaterials(); // Recargar datos
      }
    } else {
      _showNotification('El código ingresado no es válido.', isError: true);
    }

    _controller.clear();
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPushNotification() {
    _showNotification('Hola');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Línea de Producción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Escanea o ingresa el código QR',
                ),
                onSubmitted: _processInput,
              ),
            ),
            Expanded(
              child: _materials.isEmpty
                  ? const Center(child: Text('No hay registros aún.'))
                  : ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final material = _materials[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            title: Column(
                              children: [
                                // Serial en letras negras y centrado
                                Text(
                                  '${material['supplier']}${material['serial']}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  material['part_no'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12.0,
                                  ),
                                ),
                                Text(
                                  material['part_qty'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Acción al hacer clic en la card
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16.0), // Espaciado entre botones
            ElevatedButton(
              onPressed: _showPushNotification,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Cargar Datos'),
            ),
            const SizedBox(height: 16.0), // Espaciado entre botones
          ],
        ),
      ),
    );
  }
}
