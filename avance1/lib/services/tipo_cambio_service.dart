import 'api_services.dart';

class TipoCambioService {
  // Trae el tipo de cambio de compra del dolar (BCCR real)
  static Future<double> obtenerTipoCambio() async {
    final data = await ApiService.get('/tipo-cambio');
    return (data['valor'] as num).toDouble();
  }
}