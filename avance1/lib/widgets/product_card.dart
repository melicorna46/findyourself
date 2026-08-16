import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/producto.dart';
import '../services/carrito_service.dart';
import '../services/favorito_service.dart';
import 'resenas_widget.dart';

class ProductCard extends StatefulWidget {
  final Producto producto;
  final bool esFavoritoInicial;
  final VoidCallback? onQuitarFavorito;

  const ProductCard({
    super.key,
    required this.producto,
    this.esFavoritoInicial = false,
    this.onQuitarFavorito,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _esFavorito;
  bool _procesandoFav = false;

  // Motor de texto a voz (Text To Speech) para leer el producto en voz alta
  final FlutterTts _tts = FlutterTts();
  bool _leyendo = false;

  @override
  void initState() {
    super.initState();
    _esFavorito = widget.esFavoritoInicial;
    // Configuracion de la voz: espanol, velocidad y tono comodos
    _tts.setLanguage('es-ES');
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);
    // Cuando termina de leer, actualiza el boton
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _leyendo = false);
    });
  }

  // Lee en voz alta el nombre, la descripcion y el precio del producto.
  // Pensado para personas con baja vision o que prefieren escuchar.
  Future<void> _leerEnVozAlta() async {
    if (_leyendo) {
      // Si ya esta leyendo, lo detiene
      await _tts.stop();
      setState(() => _leyendo = false);
      return;
    }
    final texto =
        '${widget.producto.nombre}. ${widget.producto.descripcion ?? ''}. '
        'Precio: ${widget.producto.precio.toStringAsFixed(0)} colones.';
    setState(() => _leyendo = true);
    await _tts.speak(texto);
  }

  Future<void> _toggleFavorito() async {
    if (_procesandoFav) return;
    setState(() => _procesandoFav = true);
    try {
      if (_esFavorito) {
        await FavoritoService.quitar(widget.producto.id);
        setState(() => _esFavorito = false);
        widget.onQuitarFavorito?.call();
      } else {
        await FavoritoService.agregar(widget.producto.id);
        setState(() => _esFavorito = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.producto.nombre} agregado a favoritos'),
              backgroundColor: const Color(0xFFB8956A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar favoritos')),
        );
      }
    }
    setState(() => _procesandoFav = false);
  }

  Future<void> _agregarAlCarrito(BuildContext context) async {
    try {
      await CarritoService.agregarProducto(widget.producto.id, widget.producto.precio);
      if (context.mounted) {
        Navigator.pop(context);
        // Aviso de confirmacion claro (sugerencia de usuario: confirmar la accion)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.producto.nombre} se agrego al carrito',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF8a6840),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tts.stop(); // detiene la voz si la tarjeta se cierra
    super.dispose();
  }

  Widget _buildImagen({double? height, double? width}) {
    if (widget.producto.imagenUrl != null && widget.producto.imagenUrl!.isNotEmpty) {
      return Image.network(
        widget.producto.imagenUrl!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.diamond, size: 50, color: Color(0xFFB8860B)),
        ),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return const Center(
      child: Icon(Icons.diamond, size: 50, color: Color(0xFFB8860B)),
    );
  }

  void _mostrarDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF5F0E8),
                    child: _buildImagen(height: 180, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.producto.etiqueta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8860B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.producto.etiqueta!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  widget.producto.nombre,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.producto.descripcion ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Text(
                  '₡${widget.producto.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8860B),
                  ),
                ),
                const SizedBox(height: 12),
                // Boton de accesibilidad: leer el producto en voz alta
                Semantics(
                  button: true,
                  label: _leyendo ? 'Detener lectura' : 'Escuchar la descripcion del producto',
                  child: OutlinedButton.icon(
                    onPressed: _leerEnVozAlta,
                    icon: Icon(_leyendo ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
                    label: Text(_leyendo ? 'Detener' : 'Escuchar descripcion'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8a6840),
                      side: const BorderSide(color: Color(0xFFB8956A)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Stock disponible: ${widget.producto.stock}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _agregarAlCarrito(context),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Agregar al carrito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8860B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                // Seccion de reseñas
                ResenasWidget(productoId: widget.producto.id),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarDetalle(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      color: const Color(0xFFF5F0E8),
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildImagen(),
                    ),
                  ),
                  // Corazon de favorito
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleFavorito,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _esFavorito ? Icons.favorite : Icons.favorite_border,
                          color: _esFavorito ? Colors.red[400] : const Color(0xFF8a6840),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.producto.etiqueta != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8860B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.producto.etiqueta!,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  Text(
                    widget.producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₡${widget.producto.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFB8860B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}