import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../main.dart';

class OtpAppScreen extends StatefulWidget {
  final int usuarioId;
  final String nombre;
  final String codigoSimulado;

  const OtpAppScreen({
    super.key,
    required this.usuarioId,
    required this.nombre,
    required this.codigoSimulado,
  });

  @override
  State<OtpAppScreen> createState() => _OtpAppScreenState();
}

class _OtpAppScreenState extends State<OtpAppScreen> {
  final _codigoController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarCodigo() async {
    if (_codigoController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El codigo debe tener 6 digitos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.verificarOtpApp(
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
          const SnackBar(content: Text('Codigo incorrecto o expirado')),
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
        title: const Text('Codigo de verificacion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDD0),
                borderRadius: BorderRadius.circular(45),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  size: 48, color: Color(0xFFB8956A)),
            ),

            const SizedBox(height: 24),

            const Text(
              'Codigo enviado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3d2f22),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Hemos generado un codigo de verificacion para tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7a6150)),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DDD0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tu codigo (simulacion):',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7a6150)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.codigoSimulado,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF8a6840),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'En un entorno real este codigo se enviaria por correo electronico.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 32),

            const Text('Ingresa el codigo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 16),

            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF3d2f22),
              ),
              decoration: InputDecoration(
                hintText: '000000',
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
              'El codigo expira en 5 minutos',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificarCodigo,
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