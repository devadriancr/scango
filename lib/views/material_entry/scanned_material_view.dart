import 'package:flutter/material.dart';
import 'package:scango/services/database_service.dart';
import 'package:scango/services/api_service.dart';
import 'validate_scan_view.dart';

class ScannedMaterialView extends StatefulWidget {
  final int containerId;
  final String containerCode;

  const ScannedMaterialView({
    Key? key,
    required this.containerId,
    required this.containerCode,
  }) : super(key: key);

  @override
  _ScannedMaterialViewState createState() => _ScannedMaterialViewState();
}

class _ScannedMaterialViewState extends State<ScannedMaterialView> {
  late DatabaseService _databaseService;
  late ApiService _apiService;
  final TextEditingController _inputController = TextEditingController();
  late FocusNode _focusNode;
  List<Map<String, dynamic>> _records = [];
  bool _isProcessing = false;
  String? _partNo;
  int? _partQty;
  String? _supplier;
  String? _serial;
  bool _isDataSending = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _databaseService = DatabaseService();
    _apiService = ApiService();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _databaseService.initializeDatabase();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records =
          await _databaseService.getActiveMaterialEntries(widget.containerId);
      final filteredRecords = records
          .where((record) =>
              record['status'] == 1 &&
              record['container_id'] == widget.containerId)
          .toList();
      setState(() {
        _records = filteredRecords;
      });
      print('Registros cargados: ${_records.length}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los registros: $e')),
      );
    }
  }

  Future<void> _insertData(
      String partNo, int partQty, String supplier, String serial) async {
    final isRegistered = await _databaseService.isMaterialRegistered(
      widget.containerId,
      partNo,
      partQty,
      supplier,
      serial,
    );

    if (isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material ya está registrado.')),
      );
    } else {
      await _databaseService.addMaterialEntry(
        containerId: widget.containerId,
        partNo: partNo,
        partQty: partQty,
        supplier: supplier,
        serial: serial,
        noOrder: null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados en la base de datos.')),
      );
      _loadRecords();
    }
  }

  Future<void> _uploadScanData() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _isDataSending = true; // Disable both buttons when sending data
    });

    try {
      final recordsToUpload =
          _records.where((record) => record['status'] == 1).toList();

      for (var record in recordsToUpload) {
        final response = await _apiService.uploadScannedMaterial(
          record['part_no'],
          record['part_qty'],
          record['supplier'],
          record['serial'],
          widget.containerId,
        );

        if (response) {
          await _databaseService.updateStatus(
            record['part_no'],
            widget.containerId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar un escaneo.')),
          );
          break;
        }
      }

      if (recordsToUpload.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escaneos cargados correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros para cargar.')),
        );
      }

      _loadRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el escaneo: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _isDataSending = false; // Re-enable the buttons after processing
      });
    }
  }

  void _processInput() {
    String input = _inputController.text.trim().toUpperCase();
    List<String> dataParts = input.split(',');

    if (dataParts.length > 13) {
      setState(() {
        _partQty = int.tryParse(dataParts[10]) ?? 0;
        _supplier = dataParts[11];
        _serial = dataParts[13];
        _partNo = dataParts.last;
      });

      _insertData(_partNo!, _partQty!, _supplier!, _serial!);

      _inputController.clear();
      _focusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de entrada inválido.')),
      );
    }
  }

  void _clearFields() {
    setState(() {
      _partNo = null;
      _partQty = null;
      _supplier = null;
      _serial = null;
    });
    _inputController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.containerCode),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: (value) => _processInput(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Escanear código QR',
                hintText: 'Ingrese el código QR aquí...',
              ),
            ),
            const SizedBox(height: 8.0), // Espaciado entre input y texto
            Text(
              'Cantidad escaneada: ${_records.length}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _records.isEmpty
                  ? const Center(child: Text('No hay registros aún.'))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
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
                                  '${record['supplier']}${record['serial']}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  record['part_no'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12.0,
                                  ),
                                ),
                                Text(
                                  record['part_qty'].toString(),
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
              onPressed: _isDataSending ? null : _uploadScanData,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Enviar Datos'),
            ),
            const SizedBox(height: 16.0), // Espaciado entre botones
            ElevatedButton(
              onPressed: _isDataSending
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ValidateScanView(
                            containerId: widget.containerId,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Validar Escaneo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _databaseService.closeConnection();
    super.dispose();
  }
}
