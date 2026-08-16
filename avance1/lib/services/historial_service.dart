import 'api_services.dart';
import 'session_service.dart';

class HistorialService {
  // Obtener los pedidos del usuario actual (con sus items)
  static Future<List<dynamic>> obtenerPedidos() async {
    final data = await ApiService.get('/historial/${SessionService.usuarioId}');
    return data as List;
  }
}