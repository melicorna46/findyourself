import '../services/api_services.dart';

class Producto {
  final int id;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String? etiqueta;
  final String? imagenUrl;
  final bool activo;

  Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.etiqueta,
    this.imagenUrl,
    this.activo = true,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      categoriaId: json['categoria_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: double.parse(json['precio'].toString()),
      stock: json['stock'],
      etiqueta: json['etiqueta'],
      imagenUrl: ApiService.urlImagen(json['imagen_url']),
      activo: json['activo'] ?? true,
    );
  }
}