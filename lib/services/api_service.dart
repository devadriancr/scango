import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scango/models/container/container.dart';

class ApiService {
  static const String baseUrl =
      // "http://192.168.130.9:8088/index.php/api/containers";
      "http://192.168.170.112:8000/api/containers";
  static const String scanUrl =
      // "http://192.168.130.9:8088/index.php/api/scanned-material";
      "http://192.168.170.112:8000/api/scanned-material";
  static const String validateUrl =
      // "http://192.168.130.9:8088/index.php/api/check-material";
      "http://192.168.170.112:8000/api/check-material";
  static const String scanExirUrl =
      "http://192.168.170.112:8000/api/material-exit";

  Future<List<ContainerModel>> fetchContainers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          List<dynamic> containersJson = data['data'];
          return containersJson
              .map((json) => ContainerModel.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception("Error al obtener los datos: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  Future<bool> uploadScannedMaterial(String partNo, int partQty,
      String supplier, String serial, int containerId) async {
    final url = Uri.parse(scanUrl);
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({
      "part_no": partNo,
      "part_qty": partQty.toString(),
      "supplier": supplier,
      "serial": serial,
      "container_id": containerId.toString(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error al conectar con la API: $e');
    }
  }

  Future<Map<String, dynamic>> checkMaterial(int containerId) async {
    final url = Uri.parse(validateUrl);
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({
      "container_id": containerId,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Devuelve la respuesta completa de la API
      } else {
        throw Exception('Error al obtener los datos: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> sendMaterialExit(
    String supplier,
    String serial,
    String partNo,
    int partQty,
    int? containerId,
    String? noOrder,
  ) async {
    final url = Uri.parse(scanExirUrl);
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({
      "supplier": supplier,
      "serial": serial,
      "part_no": partNo,
      "part_qty": partQty,
      "container_id": containerId,
      "no_order": noOrder,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error al conectar con la API: $e');
    }
  }
}
