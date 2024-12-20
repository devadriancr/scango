import 'package:scango/models/container/container.dart';
import 'package:scango/services/api_service.dart';

class ContainerController {
  final ApiService _apiService = ApiService();

  Future<List<ContainerModel>> getContainers() async {
    return await _apiService.fetchContainers();
  }
}
