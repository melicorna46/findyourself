import 'package:flutter/material.dart';
import '../services/historial_service.dart';
import '../services/api_services.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> _pedidos = [];
  bool _cargando = true;

  final Color _cafe = const Color(0xFFB8956A);
  final Color _cafeOscuro = const Color(0xFF8a6840);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final pedidos = await HistorialService.obtenerPedidos();
      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Icono segun metodo de pago
  IconData _iconoMetodo(String metodo) {
    if (metodo.contains('Tarjeta')) return Icons.credit_card;
    if (metodo.contains('SINPE')) return Icons.smartphone;
    if (metodo.contains('PayPal')) return Icons.account_balance_wallet;
    return Icons.attach_money;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Mis Pedidos',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: _cafe,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: _cafe))
          : _pedidos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 70, color: Colors.black26),
                      SizedBox(height: 12),
                      Text('Aun no tienes pedidos',
                          style: TextStyle(color: Color(0xFF7a6150), fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: _cafe,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pedidos.length,
                    itemBuilder: (context, index) => _tarjetaPedido(_pedidos[index]),
                  ),
                ),
    );
  }

  Widget _tarjetaPedido(Map<String, dynamic> pedido) {
    final items = (pedido['items'] as List?) ?? [];
    final total = double.tryParse(pedido['total'].toString()) ?? 0;
    final guia = pedido['numero_guia'];
    final metodo = pedido['metodo_pago']?.toString() ?? '';
    final fecha = pedido['fecha']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D5C3)),
        boxShadow: const [BoxShadow(color: Color(0x11B8956A), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del pedido
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: _cafeOscuro, size: 20),
                const SizedBox(width: 8),
                Text('Pedido #${pedido['id']}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _cafeOscuro)),
                const Spacer(),
                Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          // Items del pedido
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ApiService.urlImagen(item['imagen_url']),
                              width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44, height: 44,
                                color: const Color(0xFFF5F0E8),
                                child: const Icon(Icons.diamond, size: 20, color: Color(0xFFB8860B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item['nombre'] ?? '',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Text('x${item['cantidad']}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    )),
                const Divider(),
                // Metodo de pago y guia
                Row(
                  children: [
                    Icon(_iconoMetodo(metodo), size: 16, color: _cafe),
                    const SizedBox(width: 6),
                    Text(metodo, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    const Spacer(),
                    Text('\u20a1${total.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _cafeOscuro, fontSize: 16)),
                  ],
                ),
                if (guia != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 15, color: Color(0xFF5a6b82)),
                        const SizedBox(width: 6),
                        Text('Guia: $guia',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5a6b82))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}