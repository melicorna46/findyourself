import 'api_services.dart';
import 'session_service.dart';

class PedidoService {
  static Future<Map<String, dynamic>> crearPedido({
    required String direccionEnvio,
    required String metodoPago,
    required String provincia,
    String? notas,
  }) async {
    final result = await ApiService.post('/pedidos', {
      'usuarioId': SessionService.usuarioId, // usuario que inicio sesion
      'direccionEnvio': direccionEnvio,
      'metodoPago': metodoPago,
      'provincia': provincia,
      'notas': notas ?? '',
    });
    return result;
  }
}