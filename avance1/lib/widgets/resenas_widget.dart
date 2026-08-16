import 'package:flutter/material.dart';
import '../services/resena_service.dart';

class ResenasWidget extends StatefulWidget {
  final int productoId;

  const ResenasWidget({super.key, required this.productoId});

  @override
  State<ResenasWidget> createState() => _ResenasWidgetState();
}

class _ResenasWidgetState extends State<ResenasWidget> {
  Map<String, dynamic>? _datos;
  bool _cargando = true;
  int _miCalificacion = 0;
  final _comentarioController = TextEditingController();
  bool _enviando = false;

  final Color _cafe = const Color(0xFFB8860B);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await ResenaService.obtenerResenas(widget.productoId);
      if (mounted) {
        setState(() {
          _datos = datos;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _publicar() async {
    if (_miCalificacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una calificacion')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await ResenaService.publicar(
        productoId: widget.productoId,
        calificacion: _miCalificacion,
        comentario: _comentarioController.text,
      );
      _comentarioController.clear();
      setState(() {
        _miCalificacion = 0;
        _enviando = false;
      });
      await _cargar(); // recargar para ver la nueva reseña
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña publicada. Gracias!')),
        );
      }
    } catch (_) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo publicar la reseña')),
        );
      }
    }
  }

  // Fila de estrellas para mostrar (no editable)
  Widget _estrellas(double calificacion, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < calificacion.round() ? Icons.star : Icons.star_border,
          color: _cafe,
          size: size,
        );
      }),
    );
  }

  // Estrellas para seleccionar (editable)
  Widget _selectorEstrellas() {
    return Row(
      children: List.generate(5, (i) {
        return IconButton(
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(),
          icon: Icon(
            i < _miCalificacion ? Icons.star : Icons.star_border,
            color: _cafe,
            size: 30,
          ),
          onPressed: () => setState(() => _miCalificacion = i + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFB8860B))),
      );
    }

    final promedio = double.tryParse(_datos?['promedio']?.toString() ?? '0') ?? 0;
    final total = _datos?['total'] ?? 0;
    final resenas = (_datos?['resenas'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        // Encabezado con promedio
        Row(
          children: [
            const Text('Reseñas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            if (total > 0) ...[
              _estrellas(promedio),
              const SizedBox(width: 6),
              Text('$promedio ($total)',
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ] else
              const Text('Se la primera en opinar',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),

        // Formulario para dejar reseña
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu calificacion:', style: TextStyle(fontSize: 13)),
              _selectorEstrellas(),
              const SizedBox(height: 8),
              TextField(
                controller: _comentarioController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Escribe tu opinion...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _publicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cafe,
                    foregroundColor: Colors.white,
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publicar reseña'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lista de reseñas existentes
        if (resenas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aun no hay reseñas para esta joya.',
                style: TextStyle(color: Colors.black45, fontSize: 13)),
          )
        else
          ...resenas.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEE6D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r['usuario_nombre'] ?? 'Anonimo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        _estrellas((r['calificacion'] ?? 0).toDouble(), size: 14),
                      ],
                    ),
                    if ((r['comentario'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r['comentario'],
                          style: const TextStyle(color: Colors.black87, fontSize: 13)),
                    ],
                  ],
                ),
              )),
      ],
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
}