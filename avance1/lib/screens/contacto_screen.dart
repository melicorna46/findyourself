import 'package:flutter/material.dart';
import '../services/consulta_service.dart';
import '../services/ubicacion_service.dart';

class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _cargando = false;

  // Listas para los dropdowns
  List<dynamic> _paises = [];
  List<dynamic> _provincias = [];
  List<dynamic> _cantones = [];
  List<dynamic> _distritos = [];

  // Selecciones actuales
  int? _paisSeleccionado;
  int? _provinciaSeleccionada;
  int? _cantonSeleccionado;
  int? _distritoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarPaises();
  }

  // Carga los paises al abrir la pantalla
  Future<void> _cargarPaises() async {
    try {
      final data = await UbicacionService.obtenerPaises();
      setState(() => _paises = data);
    } catch (e) {
      debugPrint('Error cargando paises: $e');
    }
  }

  // Cuando el usuario selecciona un pais carga las provincias — equivalente a AJAX
  Future<void> _onPaisSeleccionado(int paisId) async {
    setState(() {
      _paisSeleccionado = paisId;
      _provincias = [];
      _cantones = [];
      _distritos = [];
      _provinciaSeleccionada = null;
      _cantonSeleccionado = null;
      _distritoSeleccionado = null;
    });
    try {
      final data = await UbicacionService.obtenerProvincias(paisId);
      setState(() => _provincias = data);
    } catch (e) {
      debugPrint('Error cargando provincias: $e');
    }
  }

  // Cuando el usuario selecciona una provincia carga los cantones — equivalente a AJAX
  Future<void> _onProvinciaSeleccionada(int provinciaId) async {
    setState(() {
      _provinciaSeleccionada = provinciaId;
      _cantones = [];
      _distritos = [];
      _cantonSeleccionado = null;
      _distritoSeleccionado = null;
    });
    try {
      final data = await UbicacionService.obtenerCantones(provinciaId);
      setState(() => _cantones = data);
    } catch (e) {
      debugPrint('Error cargando cantones: $e');
    }
  }

  // Cuando el usuario selecciona un canton carga los distritos — equivalente a AJAX
  Future<void> _onCantonSeleccionado(int cantonId) async {
    setState(() {
      _cantonSeleccionado = cantonId;
      _distritos = [];
      _distritoSeleccionado = null;
    });
    try {
      final data = await UbicacionService.obtenerDistritoss(cantonId);
      setState(() => _distritos = data);
    } catch (e) {
      debugPrint('Error cargando distritos: $e');
    }
  }

  Future<void> _enviarConsulta() async {
    if (_nombreController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await ConsultaService.enviarConsulta(
        nombre: _nombreController.text,
        telefono: '',
        correo: _correoController.text,
        motivo: '',
        mensaje: _mensajeController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta enviada exitosamente')),
        );
        _nombreController.clear();
        _correoController.clear();
        _mensajeController.clear();
        setState(() {
          _paisSeleccionado = null;
          _provinciaSeleccionada = null;
          _cantonSeleccionado = null;
          _distritoSeleccionado = null;
          _provincias = [];
          _cantones = [];
          _distritos = [];
        });
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
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Contacto',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info de contacto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4B896)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.store_outlined, color: Color(0xFFB8956A), size: 40),
                  SizedBox(height: 8),
                  Text('Find Your Self',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3d2f22))),
                  SizedBox(height: 4),
                  Text('Joyeria artesanal unica',
                      style: TextStyle(color: Color(0xFF7a6150))),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Envianos un mensaje',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 16),

            // Nombre
            _campo(controller: _nombreController, label: 'Nombre', icono: Icons.person_outline),
            const SizedBox(height: 12),

            // Correo
            _campo(controller: _correoController, label: 'Correo', icono: Icons.email_outlined, teclado: TextInputType.emailAddress),
            const SizedBox(height: 24),

            const Text('Ubicacion',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3d2f22))),
            const SizedBox(height: 8),
            const Text('Selecciona tu ubicacion paso a paso',
                style: TextStyle(fontSize: 12, color: Color(0xFF7a6150))),
            const SizedBox(height: 16),

            // Dropdown Pais
            _dropdown(
              label: 'Pais',
              icono: Icons.public,
              items: _paises,
              valorSeleccionado: _paisSeleccionado,
              onChanged: (valor) => _onPaisSeleccionado(valor!),
            ),
            const SizedBox(height: 12),

            // Dropdown Provincia
            _dropdown(
              label: 'Provincia',
              icono: Icons.map_outlined,
              items: _provincias,
              valorSeleccionado: _provinciaSeleccionada,
              onChanged: _paisSeleccionado == null
                  ? null
                  : (valor) => _onProvinciaSeleccionada(valor!),
            ),
            const SizedBox(height: 12),

            // Dropdown Canton
            _dropdown(
              label: 'Canton',
              icono: Icons.location_city_outlined,
              items: _cantones,
              valorSeleccionado: _cantonSeleccionado,
              onChanged: _provinciaSeleccionada == null
                  ? null
                  : (valor) => _onCantonSeleccionado(valor!),
            ),
            const SizedBox(height: 12),

            // Dropdown Distrito
            _dropdown(
              label: 'Distrito',
              icono: Icons.place_outlined,
              items: _distritos,
              valorSeleccionado: _distritoSeleccionado,
              onChanged: _cantonSeleccionado == null
                  ? null
                  : (valor) => setState(() => _distritoSeleccionado = valor),
            ),
            const SizedBox(height: 24),

            // Mensaje
            TextField(
              controller: _mensajeController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                prefixIcon: const Icon(Icons.message_outlined, color: Color(0xFFB8956A)),
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

            // Boton enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _enviarConsulta,
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
                    : const Text('Enviar consulta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      decoration: InputDecoration(
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
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icono,
    required List<dynamic> items,
    required int? valorSeleccionado,
    required void Function(int?)? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: valorSeleccionado,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, color: const Color(0xFFB8956A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: onChanged == null
                ? Colors.black12
                : const Color(0xFFD4B896),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8956A), width: 2),
        ),
        filled: onChanged == null,
        fillColor: onChanged == null ? Colors.black.withValues(alpha: 0.04) : null,
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['nombre']),
        );
      }).toList(),
      hint: Text(
        onChanged == null ? 'Selecciona primero el anterior' : 'Selecciona $label',
        style: const TextStyle(fontSize: 13, color: Colors.black38),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }
}