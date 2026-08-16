class Pedido {
  final int id;
  final int usuarioId;
  final String estado;
  final String direccionEnvio;
  final String metodoPago;
  final double total;
  final String? notas;

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.estado,
    required this.direccionEnvio,
    required this.metodoPago,
    required this.total,
    this.notas,
  });

  factory Pedido.fromRow(List<dynamic> row) {
    return Pedido(
      id: row[0] as int,
      usuarioId: row[1] as int,
      estado: row[2] as String,
      direccionEnvio: row[3] as String,
      metodoPago: row[4] as String,
      total: double.parse(row[5].toString()),
      notas: row[6] as String?,
    );
  }
}