class SessionService {
  static int? _usuarioId;
  static String? _nombre;

  static void guardar(int usuarioId, String nombre) {
    _usuarioId = usuarioId;
    _nombre = nombre;
  }

  static int get usuarioId => _usuarioId ?? 0;
  static String get nombre => _nombre ?? '';

  static void cerrar() {
    _usuarioId = null;
    _nombre = null;
  }
}