import 'api_services.dart';
import 'session_service.dart';
import '../models/producto.dart';

class FavoritoService {
  // Listar favoritos del usuario actual
  static Future<List<Producto>> obtenerFavoritos() async {
    final data = await ApiService.get('/favoritos/${SessionService.usuarioId}');
    return (data as List).map((item) => Producto.fromJson(item)).toList();
  }

  // Agregar un producto a favoritos
  static Future<void> agregar(int productoId) async {
    await ApiService.post('/favoritos', {
      'usuarioId': SessionService.usuarioId,
      'productoId': productoId,
    });
  }

  // Quitar un producto de favoritos
  static Future<void> quitar(int productoId) async {
    await ApiService.delete('/favoritos/${SessionService.usuarioId}/$productoId');
  }
}