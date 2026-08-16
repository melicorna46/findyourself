import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class VerificarCorreoScreen extends StatefulWidget {
  final int usuarioId;
  final String correo;
  final String otpSecret;

  const VerificarCorreoScreen({
    super.key,
    required this.usuarioId,
    required this.correo,
    required this.otpSecret,
  });

  @override
  State<VerificarCorreoScreen> createState() => _VerificarCorreoScreenState();
}

class _VerificarCorreoScreenState extends State<VerificarCorreoScreen> {
  final _tokenController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarToken() async {
    if (_tokenController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El codigo debe tener 6 digitos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await AuthService.verificarCorreo(
        usuarioId: widget.usuarioId,
        token: _tokenController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente. Inicia sesion.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
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
        title: const Text('Verificar correo',
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
              child: const Icon(Icons.mark_email_unread_outlined,
                  size: 48, color: Color(0xFFB8956A)),
            ),

            const SizedBox(height: 24),

            const Text(
              'Verifica tu correo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3d2f22),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Enviamos un codigo de verificacion a\n${widget.correo}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7a6150),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _tokenController,
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

            const SizedBox(height: 8),

            const Text(
              'El codigo expira en 10 minutos',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificarToken,
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
    _tokenController.dispose();
    super.dispose();
  }
}