import 'api_services.dart';
import '../models/producto.dart';

class BusquedaService {
  // Busca/filtra productos por texto, rango de precio y categoria
  static Future<List<Producto>> buscar({
    String? texto,
    double? precioMin,
    double? precioMax,
    int? categoria,
  }) async {
    // Armamos los parametros del query solo con los filtros que llegaron
    final params = <String>[];
    if (texto != null && texto.isNotEmpty) params.add('texto=$texto');
    if (precioMin != null) params.add('precioMin=${precioMin.toInt()}');
    if (precioMax != null) params.add('precioMax=${precioMax.toInt()}');
    if (categoria != null) params.add('categoria=$categoria');

    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await ApiService.get('/busqueda$query');
    return (data as List).map((item) => Producto.fromJson(item)).toList();
  }
}