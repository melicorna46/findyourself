import 'package:flutter/material.dart';
import '../models/carrito_item.dart';
import '../services/carrito_service.dart';
import 'checkout_screen.dart';

class CarritoScreen extends StatefulWidget {
  final Function(int) onActualizar;

  const CarritoScreen({super.key, required this.onActualizar});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<CarritoItem> _items = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    try {
      final items = await CarritoService.obtenerItems();
      if (mounted) {
        setState(() {
          _items = items;
          _cargando = false;
        });
        widget.onActualizar(_items.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  double get _total => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _eliminarItem(int itemId) async {
    await CarritoService.eliminarItem(itemId);
    _cargarCarrito();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Mi Carrito',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB8956A)))
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.black26),
                      SizedBox(height: 12),
                      Text('Tu carrito esta vacio',
                          style: TextStyle(color: Color(0xFF7a6150))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE8DDD0)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFD4B896),
                                backgroundImage: item.imagenUrl != null
                                    ? NetworkImage(item.imagenUrl!)
                                    : null,
                                child: item.imagenUrl == null
                                    ? const Icon(Icons.diamond, color: Color(0xFF8a6840))
                                    : null,
                              ),
                              title: Text(item.nombreProducto,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3d2f22))),
                              subtitle: Text('Cantidad: ${item.cantidad}',
                                  style: const TextStyle(color: Color(0xFF7a6150))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₡${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8a6840),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _eliminarItem(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Color(0x11B8956A), blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3d2f22))),
                              Text(
                                '₡${_total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8a6840),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _items.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CheckoutScreen(total: _total),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB8956A),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Proceder al pago',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}