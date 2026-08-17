import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://findyourself-backend.onrender.com';

  // Arma la URL completa de una imagen usando SIEMPRE el baseUrl actual.
  // Sirve tanto si en la base viene la ruta relativa (/imagenes/x.jpg)
  // como si viene una URL vieja completa (http://10.0.2.2:3000/imagenes/x.jpg).
  // Asi, al cambiar baseUrl (hosting), todas las imagenes se acomodan solas.
  static String urlImagen(String? ruta) {
    if (ruta == null || ruta.isEmpty) return '';
    if (ruta.startsWith('http')) {
      final i = ruta.indexOf('/imagenes');
      if (i != -1) return '$baseUrl${ruta.substring(i)}';
      return ruta;
    }
    return '$baseUrl$ruta';
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error: ${response.statusCode}');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error'] ?? 'Error: ${response.statusCode}');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error: ${response.statusCode}');
    }
  }
}