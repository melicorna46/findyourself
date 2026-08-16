class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activa;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activa = true,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activa: json['activa'] ?? true,
    );
  }
}