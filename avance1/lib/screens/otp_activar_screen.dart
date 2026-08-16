import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class OtpActivarScreen extends StatefulWidget {
  final int usuarioId;
  final String otpSecret;

  const OtpActivarScreen({
    super.key,
    required this.usuarioId,
    required this.otpSecret,
  });

  @override
  State<OtpActivarScreen> createState() => _OtpActivarScreenState();
}

class _OtpActivarScreenState extends State<OtpActivarScreen> {
  final _codigoController = TextEditingController();
  bool _cargando = false;
  bool _activado = false;

  Future<void> _activarOtp() async {
    if (_codigoController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El codigo debe tener 6 digitos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await AuthService.activarOtp(
        usuarioId: widget.usuarioId,
        codigo: _codigoController.text,
      );

      setState(() => _activado = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Codigo incorrecto: ${e.toString()}')),
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
        title: const Text('Configurar Google Authenticator',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _activado ? _pantallaExito() : _pantallaConfiguracion(),
      ),
    );
  }

  Widget _pantallaConfiguracion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instrucciones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4B896)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Configura el doble factor',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22))),
              SizedBox(height: 12),
              Text('Sigue estos pasos:',
                  style: TextStyle(color: Color(0xFF7a6150), fontSize: 13)),
              SizedBox(height: 8),
              Text('1. Abre Google Authenticator en tu celular',
                  style: TextStyle(fontSize: 13, color: Color(0xFF3d2f22))),
              SizedBox(height: 4),
              Text('2. Toca el + y selecciona "Ingresar clave de configuracion"',
                  style: TextStyle(fontSize: 13, color: Color(0xFF3d2f22))),
              SizedBox(height: 4),
              Text('3. Copia la clave secreta que aparece abajo',
                  style: TextStyle(fontSize: 13, color: Color(0xFF3d2f22))),
              SizedBox(height: 4),
              Text('4. Escribe el codigo de 6 digitos que aparece',
                  style: TextStyle(fontSize: 13, color: Color(0xFF3d2f22))),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Secret key
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8DDD0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu clave secreta:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.otpSecret.substring(0, 16),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8a6840),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF8a6840)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.otpSecret));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clave copiada al portapapeles')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text('Verificar codigo',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3d2f22))),
        const SizedBox(height: 8),
        const Text('Ingresa el codigo de 6 digitos de Google Authenticator para confirmar la configuracion.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
        const SizedBox(height: 16),

        // Campo codigo
        TextField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
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

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargando ? null : _activarOtp,
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
                : const Text('Activar doble factor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _pantallaExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.verified_user, size: 80, color: Color(0xFFB8956A)),
        const SizedBox(height: 24),
        const Text(
          'Doble factor activado',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3d2f22),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu cuenta esta protegida. Cada vez que inicies sesion necesitaras el codigo de Google Authenticator.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF7a6150), height: 1.5),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8956A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ir al inicio de sesion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }
}