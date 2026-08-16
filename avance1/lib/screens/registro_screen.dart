import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verificar_correo_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _preguntaController = TextEditingController();
  final _respuestaController = TextEditingController();

  bool _obscurePassword = true;
  bool _cargando = false;
  bool _buscandoCedula = false;
  String? _mensajeCedula;

  List<String> _erroresUsuario = [];
  List<String> _erroresPassword = [];

  bool get _tieneMayuscula => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _tieneMinuscula => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _tieneNumero => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _tieneSimbolo => RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(_passwordController.text);
  bool get _tieneLongitud => _passwordController.text.length >= 8;

  @override
  void initState() {
    super.initState();
    _usuarioController.addListener(() {
      setState(() {
        _erroresUsuario = AuthService.validarUsuario(_usuarioController.text);
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _erroresPassword = AuthService.validarPassword(_passwordController.text);
      });
    });
  }

  // Consulta el TSE y autocompleta nombre y apellido
  Future<void> _consultarCedula() async {
    final cedula = _cedulaController.text.trim();

    // Solo consulta si la cedula tiene 9 digitos
    if (cedula.length != 9) {
      setState(() => _mensajeCedula = null);
      return;
    }

    setState(() {
      _buscandoCedula = true;
      _mensajeCedula = null;
    });

    try {
      final datos = await AuthService.consultarCedula(cedula);
      // El TSE encontro la persona: autocompletamos los campos
      setState(() {
        _nombreController.text = datos['nombre'] ?? '';
        _apellidoController.text =
            '${datos['apellido1'] ?? ''} ${datos['apellido2'] ?? ''}'.trim();
        _mensajeCedula = 'Datos encontrados en el TSE';
      });
    } catch (e) {
      // Cedula no encontrada: dejamos que la persona escriba manualmente
      setState(() {
        _mensajeCedula = 'Cedula no registrada, escribe tus datos manualmente';
      });
    }

    setState(() => _buscandoCedula = false);
  }

  Future<void> _registrar() async {
    if (_nombreController.text.isEmpty ||
        _apellidoController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _usuarioController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _preguntaController.text.isEmpty ||
        _respuestaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (_erroresUsuario.isNotEmpty || _erroresPassword.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrige los errores antes de continuar')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.registrar(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        correo: _correoController.text,
        nombreUsuario: _usuarioController.text,
        contrasena: _passwordController.text,
        preguntaSeguridad: _preguntaController.text,
        respuestaSeguridad: _respuestaController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificarCorreoScreen(
              usuarioId: resultado['usuarioId'],
              correo: _correoController.text,
              otpSecret: resultado['otpSecret'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Crear cuenta',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informacion personal',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 8),
            const Text('Escribe tu cedula (9 digitos) y autocompletamos tus datos desde el TSE.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
            const SizedBox(height: 16),

            TextField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _consultarCedula(),
              decoration: _decoracion('Cedula', Icons.badge_outlined).copyWith(
                suffixIcon: _buscandoCedula
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB8956A),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_mensajeCedula != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _mensajeCedula!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _mensajeCedula!.contains('encontrados')
                        ? const Color(0xFF8a6840)
                        : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            _campo(controller: _nombreController, label: 'Nombre', icono: Icons.person_outline),
            const SizedBox(height: 12),

            _campo(controller: _apellidoController, label: 'Apellido', icono: Icons.person_outline),
            const SizedBox(height: 12),

            _campo(controller: _correoController, label: 'Correo', icono: Icons.email_outlined, teclado: TextInputType.emailAddress),
            const SizedBox(height: 24),

            const Text('Credenciales de acceso',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 8),
            const Text('El usuario debe tener minimo 10 caracteres, mayuscula, minuscula y numero.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
            const SizedBox(height: 16),

            TextField(
              controller: _usuarioController,
              decoration: _decoracion('Usuario', Icons.account_circle_outlined),
            ),
            if (_erroresUsuario.isNotEmpty && _usuarioController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _erroresUsuario.map((e) => Text(
                    '• $e',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _decoracion('Contrasena', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFFB8956A),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            if (_passwordController.text.isNotEmpty)
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
            const SizedBox(height: 24),

            const Text('Pregunta de seguridad',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 8),
            const Text('Se usara para recuperar tu contrasena.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
            const SizedBox(height: 16),

            _campo(controller: _preguntaController, label: 'Pregunta de seguridad', icono: Icons.help_outline),
            const SizedBox(height: 12),

            _campo(controller: _respuestaController, label: 'Respuesta', icono: Icons.question_answer_outlined),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _registrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8956A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear cuenta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Ya tengo una cuenta',
                  style: TextStyle(
                    color: Color(0xFFB8956A),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: _decoracion(label, icono),
    );
  }

  InputDecoration _decoracion(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: const Color(0xFFB8956A)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4B896)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _preguntaController.dispose();
    _respuestaController.dispose();
    super.dispose();
  }
}