import 'package:flutter/material.dart';
import 'package:scango/services/api_service.dart';

class ValidateScanView extends StatefulWidget {
  final int containerId;

  const ValidateScanView({
    Key? key,
    required this.containerId,
  }) : super(key: key);

  @override
  State<ValidateScanView> createState() => _ValidateScanViewState();
}

class _ValidateScanViewState extends State<ValidateScanView> {
  final ApiService _apiService = ApiService();
  List<dynamic> materialNotFound = [];
  int quantityNotFound = 0;
  bool isLoading = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _validateScan();
  }

  Future<void> _validateScan() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await _apiService.checkMaterial(widget.containerId);

      setState(() {
        materialNotFound = response['materialNotFound'] ?? [];
        quantityNotFound = response['quantityNotFound'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Método para recargar la vista al hacer pull-to-refresh
  Future<void> _onRefresh() async {
    await _validateScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Escaneo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh:
              _onRefresh, // Función que se llama cuando el gesto de refresh ocurre
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Cantidad faltante: $quantityNotFound',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: materialNotFound.length,
                            itemBuilder: (context, index) {
                              final material = materialNotFound[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(
                                    '${material['serial'] ?? 'Sin Serial'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Espacio entre los elementos
                                    children: [
                                      Text(
                                        '${material['part_no']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal),
                                      ),
                                      Text(
                                        '${material['part_qty']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Regresar a la vista anterior
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Regresar'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
