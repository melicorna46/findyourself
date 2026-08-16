import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/favorito_service.dart';
import '../widgets/product_card.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<Producto> _favoritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    setState(() => _cargando = true);
    try {
      final favs = await FavoritoService.obtenerFavoritos();
      if (mounted) {
        setState(() {
          _favoritos = favs;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text('Mis Favoritos',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFFB8956A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFavoritos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB8956A)))
          : _favoritos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 70, color: Colors.red[200]),
                      const SizedBox(height: 12),
                      const Text(
                        'Aun no tienes favoritos',
                        style: TextStyle(color: Color(0xFF7a6150), fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toca el corazon en una joya para guardarla aqui',
                        style: TextStyle(color: Color(0xFF9a8672), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarFavoritos,
                  color: const Color(0xFFB8956A),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _favoritos.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        producto: _favoritos[index],
                        esFavoritoInicial: true,
                        onQuitarFavorito: () {
                          // al quitar, recargar la lista
                          setState(() => _favoritos.removeAt(index));
                        },
                      );
                    },
                  ),
                ),
    );
  }
}