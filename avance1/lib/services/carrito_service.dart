import 'api_services.dart';
import 'session_service.dart';
import '../models/carrito_item.dart';

class CarritoService {
  static Future<List<CarritoItem>> obtenerItems() async {
    final data = await ApiService.get('/carrito/${SessionService.usuarioId}');
    return (data as List).map((item) => CarritoItem.fromJson(item)).toList();
  }

  static Future<void> agregarProducto(int productoId, double precio) async {
    await ApiService.post('/carrito/agregar', {
      'usuarioId': SessionService.usuarioId,
      'productoId': productoId,
      'precio': precio,
    });
  }

  static Future<void> eliminarItem(int itemId) async {
    await ApiService.delete('/carrito/item/$itemId');
  }
}