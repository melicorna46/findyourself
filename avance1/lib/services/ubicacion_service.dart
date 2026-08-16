import 'api_services.dart';

//Hace las peticiones HTTP a cada endpoint y devuelve los datos a la pantalla.

class UbicacionService {
  // Obtener todos los paises
  static Future<List<dynamic>> obtenerPaises() async {
    final data = await ApiService.get('/ubicacion/paises');
    return data;
  }

  // Obtener provincias segun el pais seleccionado

  //// Llama al backend con el ID del pais, espera la respuesta y actualiza el dropdown de provincias
  static Future<List<dynamic>> obtenerProvincias(int paisId) async {
    final data = await ApiService.get('/ubicacion/provincias/$paisId'); 
    return data;
  }

  // Obtener cantones segun la provincia seleccionada
  static Future<List<dynamic>> obtenerCantones(int provinciaId) async {
    final data = await ApiService.get('/ubicacion/cantones/$provinciaId');
    return data;
  }

  // Obtener distritos segun el canton seleccionado
  static Future<List<dynamic>> obtenerDistritoss(int cantonId) async {
    final data = await ApiService.get('/ubicacion/distritos/$cantonId');
    return data;
  }
}