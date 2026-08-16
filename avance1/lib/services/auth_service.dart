import 'api_services.dart';

class AuthService {
  // Registrar usuario
  static Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String nombreUsuario,
    required String contrasena,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
  }) async {
    final data = await ApiService.post('/auth/registro', {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'nombre_usuario': nombreUsuario,
      'contrasena': contrasena,
      'pregunta_seguridad': preguntaSeguridad,
      'respuesta_seguridad': respuestaSeguridad,
    });
    return data;
  }

  // Consultar cedula en el TSE (autocompletar nombre y apellidos)
  static Future<Map<String, dynamic>> consultarCedula(String cedula) async {
    final data = await ApiService.get('/auth/consultar-cedula/$cedula');
    return data;
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String nombreUsuario,
    required String contrasena,
  }) async {
    final data = await ApiService.post('/auth/login', {
      'nombre_usuario': nombreUsuario,
      'contrasena': contrasena,
    });
    return data;
  }

  // Verificar OTP
  static Future<Map<String, dynamic>> verificarOtp({
    required int usuarioId,
    required String codigo,
  }) async {
    final data = await ApiService.post('/auth/verificar-otp', {
      'usuarioId': usuarioId,
      'codigo': codigo,
    });
    return data;
  }

  // Recuperar password
  static Future<Map<String, dynamic>> recuperarPassword({
    required String nombreUsuario,
    required String respuestaSeguridad,
    required String nuevaContrasena,
  }) async {
    final data = await ApiService.post('/auth/recuperar', {
      'nombre_usuario': nombreUsuario,
      'respuesta_seguridad': respuestaSeguridad,
      'nueva_contrasena': nuevaContrasena,
    });
    return data;
  }

  // Activar OTP
  static Future<Map<String, dynamic>> activarOtp({
    required int usuarioId,
    required String codigo,
  }) async {
    final data = await ApiService.post('/auth/activar-otp', {
      'usuarioId': usuarioId,
      'codigo': codigo,
    });
    return data;
  }

  // Auditoría
  static Future<List<dynamic>> obtenerAuditoria(int usuarioId) async {
    final data = await ApiService.get('/auth/auditoria/$usuarioId');
    return data;
  }

  // Validar política de usuario en Flutter
  static List<String> validarUsuario(String usuario) {
    List<String> errores = [];
    if (usuario.length < 10) errores.add('Minimo 10 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(usuario)) errores.add('Al menos una mayuscula');
    if (!RegExp(r'[a-z]').hasMatch(usuario)) errores.add('Al menos una minuscula');
    if (!RegExp(r'[0-9]').hasMatch(usuario)) errores.add('Al menos un numero');
    return errores;
  }

  // Validar política de password en Flutter
  static List<String> validarPassword(String password) {
    List<String> errores = [];
    if (password.length < 8) errores.add('Minimo 8 caracteres');
    if (!RegExp(r'[A-Z]').hasMatch(password)) errores.add('Al menos una mayuscula');
    if (!RegExp(r'[a-z]').hasMatch(password)) errores.add('Al menos una minuscula');
    if (!RegExp(r'[0-9]').hasMatch(password)) errores.add('Al menos un numero');
    if (!RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) {
      errores.add('Al menos un simbolo');
    }
    return errores;
  }

  // Generar OTP propio
  static Future<Map<String, dynamic>> generarOtpApp(int usuarioId) async {
    final data = await ApiService.post('/auth/generar-otp-app', {
      'usuarioId': usuarioId,
    });
    return data;
  }

  // Verificar OTP propio
  static Future<Map<String, dynamic>> verificarOtpApp({
    required int usuarioId,
    required String codigo,
  }) async {
    final data = await ApiService.post('/auth/verificar-otp-app', {
      'usuarioId': usuarioId,
      'codigo': codigo,
    });
    return data;
  }

  // Verificar correo
  static Future<Map<String, dynamic>> verificarCorreo({
    required int usuarioId,
    required String token,
  }) async {
    final data = await ApiService.post('/auth/verificar-correo', {
      'usuarioId': usuarioId,
      'token': token,
    });
    return data;
  }

  // Obtener pregunta de seguridad
  static Future<Map<String, dynamic>> obtenerPregunta(String nombreUsuario) async {
    final data = await ApiService.get('/auth/pregunta/$nombreUsuario');
    return data;
  }

  // Recuperar con token por correo
  static Future<Map<String, dynamic>> recuperarConToken({
    required String nombreUsuario,
    required String respuestaSeguridad,
  }) async {
    final data = await ApiService.post('/auth/recuperar-con-token', {
      'nombre_usuario': nombreUsuario,
      'respuesta_seguridad': respuestaSeguridad,
    });
    return data;
  }

  // Cambiar password con token
  static Future<Map<String, dynamic>> cambiarPassword({
    required int usuarioId,
    required String token,
    required String nuevaContrasena,
  }) async {
    final data = await ApiService.post('/auth/cambiar-password', {
      'usuarioId': usuarioId,
      'token': token,
      'nueva_contrasena': nuevaContrasena,
    });
    return data;
  }
}