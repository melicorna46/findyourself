import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../main.dart';

class OtpScreen extends StatefulWidget {
  final int usuarioId;
  final String nombre;

  const OtpScreen({
    super.key,
    required this.usuarioId,
    required this.nombre,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codigoController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarOtp() async {
    if (_codigoController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El codigo debe tener 6 digitos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.verificarOtp(
        usuarioId: widget.usuarioId,
        codigo: _codigoController.text,
      );

      SessionService.guardar(widget.usuarioId, resultado['nombre']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codigo incorrecto. Intenta de nuevo.')),
        );
      }
    }

    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Verificacion',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDD0),
                borderRadius: BorderRadius.circular(45),
              ),
              child: const Icon(Icons.security, size: 48, color: Color(0xFFB8956A)),
            ),

            const SizedBox(height: 24),

            Text(
              'Hola, ${widget.nombre}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3d2f22),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Ingresa el codigo de 6 digitos de Google Authenticator para completar el inicio de sesion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7a6150),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                color: Color(0xFF3d2f22),
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 10,
                  color: Colors.black26,
                ),
                counterText: '',
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

            const SizedBox(height: 12),

            const Text(
              'El codigo cambia cada 30 segundos',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificarOtp,
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
                    : const Text('Verificar codigo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }
}