import 'api_services.dart';
import '../models/producto.dart';
import '../models/categoria.dart';

class ProductoService {
  // Obtener todos los productos
  static Future<List<Producto>> obtenerTodos() async {
    final data = await ApiService.get('/productos');
    return (data as List).map((item) => Producto.fromJson(item)).toList();
  }

  // Obtener productos por categoría
  static Future<List<Producto>> obtenerPorCategoria(int categoriaId) async {
    final data = await ApiService.get('/productos/categoria/$categoriaId');
    return (data as List).map((item) => Producto.fromJson(item)).toList();
  }

  // Obtener todas las categorías
  static Future<List<Categoria>> obtenerCategorias() async {
    final data = await ApiService.get('/productos/categorias');
    return (data as List).map((item) => Categoria.fromJson(item)).toList();
  }
}