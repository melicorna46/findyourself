import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _usuarioController = TextEditingController();
  final _respuestaController = TextEditingController();
  final _tokenController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  bool _cargando = false;
  int _paso = 1;
  String _pregunta = '';
  int _usuarioId = 0;

  bool get _tieneMayuscula => RegExp(r'[A-Z]').hasMatch(_nuevaPasswordController.text);
  bool get _tieneMinuscula => RegExp(r'[a-z]').hasMatch(_nuevaPasswordController.text);
  bool get _tieneNumero => RegExp(r'[0-9]').hasMatch(_nuevaPasswordController.text);
  bool get _tieneSimbolo => RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(_nuevaPasswordController.text);
  bool get _tieneLongitud => _nuevaPasswordController.text.length >= 8;

  @override
  void initState() {
    super.initState();
    _nuevaPasswordController.addListener(() => setState(() {}));
  }

  // Paso 1: obtener pregunta
  Future<void> _obtenerPregunta() async {
    if (_usuarioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu nombre de usuario')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.obtenerPregunta(_usuarioController.text);
      setState(() {
        _pregunta = resultado['pregunta'];
        _paso = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }

    setState(() => _cargando = false);
  }

  // Paso 2: verificar reto y enviar token al correo
  Future<void> _verificarReto() async {
    if (_respuestaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la respuesta de seguridad')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.recuperarConToken(
        nombreUsuario: _usuarioController.text,
        respuestaSeguridad: _respuestaController.text,
      );

      setState(() {
        _usuarioId = resultado['usuarioId'];
        _paso = 3;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token enviado a tu correo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }

    setState(() => _cargando = false);
  }

  // Paso 3: cambiar password con token
  Future<void> _cambiarPassword() async {
    if (_tokenController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El token debe tener 6 digitos')),
      );
      return;
    }

    if (_nuevaPasswordController.text != _confirmarPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrasenas no coinciden')),
      );
      return;
    }

    final errores = AuthService.validarPassword(_nuevaPasswordController.text);
    if (errores.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contrasena no cumple con la politica')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await AuthService.cambiarPassword(
        usuarioId: _usuarioId,
        token: _tokenController.text,
        nuevaContrasena: _nuevaPasswordController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFAF6F0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFB8956A), size: 70),
                const SizedBox(height: 16),
                const Text(
                  'Contrasena actualizada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu contrasena ha sido actualizada exitosamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7a6150)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8956A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ir al login'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }

    setState(() => _cargando = false);
  }

  Widget _indicadorRequisito(String texto, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: cumplido ? const Color(0xFF8a6840) : Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: cumplido ? const Color(0xFF8a6840) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasoIndicador(int numero, String etiqueta) {
    final activo = _paso >= numero;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFB8956A) : const Color(0xFFE8DDD0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$numero',
              style: TextStyle(
                color: activo ? Colors.white : const Color(0xFF7a6150),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(etiqueta,
            style: TextStyle(
              fontSize: 10,
              color: activo ? const Color(0xFFB8956A) : Colors.black38,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Recuperar contrasena',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de pasos
            Row(
              children: [
                _pasoIndicador(1, 'Usuario'),
                Expanded(child: Container(height: 1, color: const Color(0xFFD4B896))),
                _pasoIndicador(2, 'Reto'),
                Expanded(child: Container(height: 1, color: const Color(0xFFD4B896))),
                _pasoIndicador(3, 'Nueva clave'),
              ],
            ),

            const SizedBox(height: 32),

            // PASO 1 — Usuario
            if (_paso == 1) ...[
              const Text('Ingresa tu usuario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3d2f22))),
              const SizedBox(height: 8),
              const Text('Te mostraremos tu pregunta de seguridad.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
              const SizedBox(height: 16),
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: const Icon(Icons.account_circle_outlined, color: Color(0xFFB8956A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4B896)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _obtenerPregunta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8956A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            // PASO 2 — Reto de seguridad
            if (_paso == 2) ...[
              const Text('Responde tu reto de seguridad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3d2f22))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DDD0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pregunta,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF3d2f22), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _respuestaController,
                decoration: InputDecoration(
                  labelText: 'Tu respuesta',
                  prefixIcon: const Icon(Icons.help_outline, color: Color(0xFFB8956A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4B896)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _verificarReto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8956A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verificar y enviar token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            // PASO 3 — Token y nueva password
            if (_paso == 3) ...[
              const Text('Revisa tu correo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3d2f22))),
              const SizedBox(height: 8),
              const Text('Ingresa el token que recibiste y crea tu nueva contrasena.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
              const SizedBox(height: 16),

              // Token
              TextField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF3d2f22)),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  labelText: 'Token del correo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4B896)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nueva password
              TextField(
                controller: _nuevaPasswordController,
                obscureText: _obscureNueva,
                decoration: InputDecoration(
                  labelText: 'Nueva contrasena',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFB8956A)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNueva ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFFB8956A),
                    ),
                    onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4B896)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
                  ),
                ),
              ),

              if (_nuevaPasswordController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4B896)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tu contrasena debe tener:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3d2f22))),
                      const SizedBox(height: 6),
                      _indicadorRequisito('Minimo 8 caracteres', _tieneLongitud),
                      _indicadorRequisito('Al menos una mayuscula', _tieneMayuscula),
                      _indicadorRequisito('Al menos una minuscula', _tieneMinuscula),
                      _indicadorRequisito('Al menos un numero', _tieneNumero),
                      _indicadorRequisito('Al menos un simbolo (!@#\$...)', _tieneSimbolo),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Confirmar password
              TextField(
                controller: _confirmarPasswordController,
                obscureText: _obscureConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar contrasena',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFB8956A)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFFB8956A),
                    ),
                    onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4B896)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _cambiarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8956A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Actualizar contrasena', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _respuestaController.dispose();
    _tokenController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }
}