import '../services/api_services.dart';

class CarritoItem {
  final int id;
  final int productoId;
  final String nombreProducto;
  final String? imagenUrl;
  int cantidad;
  final double precioUnit;

  CarritoItem({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    this.imagenUrl,
    required this.cantidad,
    required this.precioUnit,
  });

  double get subtotal => cantidad * precioUnit;

  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      id: json['id'],
      productoId: json['producto_id'],
      nombreProducto: json['nombre'],
      imagenUrl: ApiService.urlImagen(json['imagen_url']),
      cantidad: json['cantidad'],
      precioUnit: double.parse(json['precio_unit'].toString()),
    );
  }
}