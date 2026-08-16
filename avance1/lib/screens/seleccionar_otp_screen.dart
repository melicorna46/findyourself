import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'otp_app_screen.dart';

class SeleccionarOtpScreen extends StatefulWidget {
  final int usuarioId;
  final String nombre;
  final String otpUrl;

  const SeleccionarOtpScreen({
    super.key,
    required this.usuarioId,
    required this.nombre,
    required this.otpUrl,
  });

  @override
  State<SeleccionarOtpScreen> createState() => _SeleccionarOtpScreenState();
}

class _SeleccionarOtpScreenState extends State<SeleccionarOtpScreen> {
  bool _cargando = false;

  Future<void> _usarOtpApp() async {
    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.generarOtpApp(widget.usuarioId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpAppScreen(
              usuarioId: widget.usuarioId,
              nombre: widget.nombre,
              codigoSimulado: resultado['codigo'],
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

  void _usarAuthenticator() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          usuarioId: widget.usuarioId,
          nombre: widget.nombre,
        ),
      ),
    );
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
            const SizedBox(height: 20),

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
              'Elige como verificar tu identidad',
              style: TextStyle(fontSize: 14, color: Color(0xFF7a6150)),
            ),

            const SizedBox(height: 24),

            // QR para Google Authenticator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4B896)),
                boxShadow: const [
                  BoxShadow(color: Color(0x11B8956A), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Google Authenticator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escanea el QR con Google Authenticator',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF7a6150)),
                  ),
                  const SizedBox(height: 16),

                  // QR Code
                  QrImageView(
                    data: widget.otpUrl,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _usarAuthenticator,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Ya escane el QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8956A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFD4B896))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: Color(0xFF7a6150))),
                ),
                Expanded(child: Divider(color: Color(0xFFD4B896))),
              ],
            ),

            const SizedBox(height: 20),

            // Opción OTP propio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4B896)),
                boxShadow: const [
                  BoxShadow(color: Color(0x11B8956A), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.sms_outlined, size: 40, color: Color(0xFFB8956A)),
                  const SizedBox(height: 8),
                  const Text(
                    'Codigo Find Your Self',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Genera un codigo de 6 digitos directamente en la app',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF7a6150)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _usarOtpApp,
                      icon: _cargando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.generating_tokens),
                      label: const Text('Generar codigo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8a6840),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }
}