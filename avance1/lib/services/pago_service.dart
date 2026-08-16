import 'api_services.dart';

class PagoService {
  // Detectar la marca de la tarjeta (Visa / Mastercard) por el numero
  static Future<String> detectarMarca(String numero) async {
    if (numero.isEmpty) return 'Desconocida';
    final data = await ApiService.get('/pagos/marca/$numero');
    return data['marca'] ?? 'Desconocida';
  }

  // Pago con tarjeta -> el backend llama al banco
  static Future<Map<String, dynamic>> pagarConTarjeta({
    required String numero,
    required String vencimiento,
    required String cvv,
    required double monto,
  }) async {
    final result = await ApiService.post('/pagos/tarjeta', {
      'numero': numero,
      'vencimiento': vencimiento,
      'cvv': cvv,
      'monto': monto,
    });
    return result;
  }

  // Pago con SINPE Movil -> el backend llama al banco
  static Future<Map<String, dynamic>> pagarConSinpe({
    required String telefono,
    required double monto,
  }) async {
    final result = await ApiService.post('/pagos/sinpe', {
      'telefono': telefono,
      'monto': monto,
    });
    return result;
  }

  // PayPal paso 1: crear la orden -> devuelve el link de aprobacion
  static Future<Map<String, dynamic>> crearOrdenPaypal({
    required double monto,
  }) async {
    final result = await ApiService.post('/paypal/crear-orden', {
      'monto': monto,
    });
    return result;
  }

  // PayPal paso 2: capturar (confirmar) el pago despues de aprobarlo
  static Future<Map<String, dynamic>> capturarPaypal({
    required String ordenId,
  }) async {
    final result = await ApiService.post('/paypal/capturar', {
      'ordenId': ordenId,
    });
    return result;
  }
}