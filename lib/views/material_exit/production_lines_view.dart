import 'package:flutter/material.dart';
import 'package:scango/services/api_service.dart';
import 'package:scango/services/database_service.dart';

class ProductionLinesView extends StatefulWidget {
  @override
  _ProductionLinesViewState createState() => _ProductionLinesViewState();
}

class _ProductionLinesViewState extends State<ProductionLinesView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = false; // Indicador para mostrar spinner
  bool _isSending = false; // Bloqueo de múltiples envíos

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndLoadMaterials();
  }

  /// Inicializa la base de datos y carga los materiales existentes
  Future<void> _initializeDatabaseAndLoadMaterials() async {
    try {
      await _dbService.initializeDatabase();
      await _loadMaterials();
    } catch (e) {
      _showNotification('Error al inicializar la base de datos: $e',
          isError: true);
    }
  }

  /// Carga los materiales desde la base de datos
  Future<void> _loadMaterials() async {
    try {
      final materials = await _dbService.getActiveMaterialExits();
      setState(() {
        _materials = materials;
      });
    } catch (e) {
      _showNotification('Error al cargar materiales: $e', isError: true);
    }
  }

  /// Procesa la entrada del usuario (código QR o texto)
  Future<void> _processInput(String input) async {
    input = input.trim();

    if (input.isEmpty) {
      _showNotification('El campo no puede estar vacío.', isError: true);
      _focusInput();
      return;
    }

    try {
      if (input.length >= 30 && input.length <= 35) {
        await _processShortInput(input);
      } else if (input.length >= 159) {
        await _processLongInput(input);
      } else {
        _showNotification('El código ingresado no es válido.', isError: true);
      }
    } catch (e) {
      _showNotification('Error al procesar el código: $e', isError: true);
    }

    _controller.clear();
    _focusInput(); // Reenfocar el campo de texto
  }

  /// Procesa entradas cortas (30-35 caracteres)
  Future<void> _processShortInput(String input) async {
    String code = input.toUpperCase();
    String noOrder = code.substring(0, 7);
    String serial = code.substring(0, 10);
    String partNo = code.substring(10, 20);
    int partQty = int.tryParse(code.substring(20, 26)) ?? 0;
    String supplier = code.substring(26, 31);

    if (await _isMaterialRegistered(
        serial: serial, partNo: partNo, partQty: partQty, supplier: supplier)) {
      _showNotification('Este material ya está registrado como salida.',
          isError: true);
    } else {
      await _registerMaterialExit(
          serial: serial,
          partNo: partNo,
          partQty: partQty,
          supplier: supplier,
          noOrder: noOrder);
    }
  }

  /// Procesa entradas largas (159 caracteres o más)
  Future<void> _processLongInput(String input) async {
    List<String> dataParts = input.toUpperCase().split(',');

    if (dataParts.length < 14) {
      _showNotification('El código ingresado no es válido.', isError: true);
      return;
    }

    int partQty = int.tryParse(dataParts[10]) ?? 0;
    String supplier = dataParts[11];
    String serial = dataParts[13];
    String partNo = dataParts.last;

    if (await _isMaterialRegistered(
        serial: serial, partNo: partNo, partQty: partQty, supplier: supplier)) {
      _showNotification('Este material ya está registrado como salida.',
          isError: true);
    } else {
      await _registerMaterialExit(
          serial: serial, partNo: partNo, partQty: partQty, supplier: supplier);
    }
  }

  /// Verifica si el material ya está registrado
  Future<bool> _isMaterialRegistered(
      {required String serial,
      required String partNo,
      required int partQty,
      required String supplier}) async {
    return await _dbService.isMaterialExitRegistered(
      serial: serial,
      partNo: partNo,
      partQty: partQty,
      supplier: supplier,
    );
  }

  /// Registra un material como salida
  Future<void> _registerMaterialExit(
      {required String serial,
      required String partNo,
      required int partQty,
      required String supplier,
      String? noOrder}) async {
    await _dbService.addMaterialExit(
      serial: serial,
      partNo: partNo,
      partQty: partQty,
      supplier: supplier,
      noOrder: noOrder,
    );
    _showNotification('Salida registrada correctamente.');
    await _loadMaterials();
  }

  /// Muestra notificaciones en pantalla
  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Reenfoca el campo de texto
  void _focusInput() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  /// Envía los datos al servidor
  Future<void> _sendData() async {
    if (_isSending) return; // Bloquear si ya se está enviando
    setState(() {
      _isSending = true;
      _isLoading = true;
    });

    try {
      final recordsToUpload = _materials.toList();
      for (var record in recordsToUpload) {
        final success = await ApiService().sendMaterialExit(
          record['supplier'],
          record['serial'],
          record['part_no'],
          record['part_qty'],
          record['container_id'],
          record['no_order'],
        );

        if (success) {
          await _dbService.updateMaterialExitStatus(record['id'], false);
        } else {
          _showNotification('Error al cargar un escaneo.', isError: true);
          break;
        }
      }

      await _loadMaterials();
    } catch (e) {
      _showNotification('Error al procesar el escaneo: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Línea de Producción'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Escanea o ingresa el código QR',
                  ),
                  onSubmitted: _processInput,
                ),
                const SizedBox(height: 8.0),
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
                                title: Text(
                                  '${material['supplier']} ${material['serial']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(material['part_no'] ?? ''),
                                    Text(material['part_qty'].toString()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendData,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator()
                      : const Text('Cargar Datos'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
