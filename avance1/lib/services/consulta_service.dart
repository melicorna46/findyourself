import 'api_services.dart';

class ConsultaService {
  static Future<void> enviarConsulta({
    required String nombre,
    required String telefono,
    required String correo,
    required String motivo,
    required String mensaje,
  }) async {
    await ApiService.post('/consultas', {
      'nombre': nombre,
      'telefono': telefono,
      'correo': correo,
      'motivo': motivo,
      'mensaje': mensaje,
    });
  }
}