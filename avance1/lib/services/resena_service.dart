import 'api_services.dart';
import 'session_service.dart';

class ResenaService {
  // Obtener reseñas de un producto + promedio
  static Future<Map<String, dynamic>> obtenerResenas(int productoId) async {
    final data = await ApiService.get('/resenas/$productoId');
    return data;
  }

  // Publicar una reseña
  static Future<void> publicar({
    required int productoId,
    required int calificacion,
    required String comentario,
  }) async {
    await ApiService.post('/resenas', {
      'productoId': productoId,
      'usuarioId': SessionService.usuarioId,
      'usuarioNombre': SessionService.nombre,
      'calificacion': calificacion,
      'comentario': comentario,
    });
  }
}