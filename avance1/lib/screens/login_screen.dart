import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/api_services.dart';
import 'registro_screen.dart';
import 'seleccionar_otp_screen.dart';
import 'recuperar_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando = false;

  Future<void> _iniciarSesion() async {
    if (_usuarioController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.login(
        nombreUsuario: _usuarioController.text,
        contrasena: _passwordController.text,
      );

      if (mounted) {
        if (resultado['requiereOtp'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SeleccionarOtpScreen(
                usuarioId: resultado['usuarioId'],
                nombre: resultado['nombre'],
                otpUrl: resultado['otpUrl'],
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              ApiService.urlImagen('/imagenes/fondo-login.jpg'),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFFAF6F0),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0x55FAF6F0)),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(height: 60),
                      Text(
                        'EST. 2025',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 6,
                          color: Color(0xFF8a6840),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'FIND YOUR SELF',
                        style: TextStyle(
                          fontSize: 34,
                          letterSpacing: 6,
                          color: Color(0xFF8a6840),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'JOYERIA ARTESANAL',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 5,
                          color: Color(0xFFB8956A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22B8956A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar sesion',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3d2f22),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bienvenida de vuelta',
                        style: TextStyle(fontSize: 13, color: Color(0xFF7a6150)),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usuarioController,
                        decoration: InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFFB8956A)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD4B896)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFB8956A), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFFB8956A)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFFB8956A),
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD4B896)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFB8956A), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecuperarPasswordScreen()),
                          ),
                          child: const Text(
                            'Olvide mi contrasena',
                            style: TextStyle(
                              color: Color(0xFFB8956A),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _iniciarSesion,
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
                              : const Text('Ingresar',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegistroScreen()),
                          ),
                          child: const Text(
                            'Crear una cuenta nueva',
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}