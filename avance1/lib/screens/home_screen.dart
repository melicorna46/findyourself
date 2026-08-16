import 'package:flutter/material.dart';
import '../services/api_services.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavegar;

  const HomeScreen({super.key, required this.onNavegar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero imagen
            Stack(
              children: [
                SizedBox(
                  height: 420,
                  width: double.infinity,
                  child: Image.network(
                    ApiService.urlImagen('/imagenes/hero-joyeria.jpg'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFD4B896),
                      child: const Center(
                        child: Icon(Icons.diamond, size: 80, color: Color(0xFFB8956A)),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xCC3d2f22),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Find Your Self',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Joyeria artesanal unica',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFD4B896),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Mensaje calido de bienvenida (sentimiento: calidez y cercania)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E9DC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.favorite, color: Color(0xFFB8956A), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nos alegra tenerte aqui. Tomate tu tiempo y encontra la pieza que va contigo.',
                        style: TextStyle(fontSize: 15, color: Color(0xFF6b5642), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Que estas buscando?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _BotonAcceso(
                          icono: Icons.local_offer_outlined,
                          texto: 'Ver Catalogo',
                          color: const Color(0xFFB8956A),
                          onTap: () => onNavegar(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BotonAcceso(
                          icono: Icons.mail_outline,
                          texto: 'Contactanos',
                          color: const Color(0xFF8a6840),
                          onTap: () => onNavegar(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuestras categorias',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3d2f22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CategoriaChip(nombre: 'Anillos', onTap: () => onNavegar(1)),
                      _CategoriaChip(nombre: 'Collares', onTap: () => onNavegar(1)),
                      _CategoriaChip(nombre: 'Aretes', onTap: () => onNavegar(1)),
                      _CategoriaChip(nombre: 'Pulseras', onTap: () => onNavegar(1)),
                    ],
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

class _BotonAcceso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _BotonAcceso({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icono, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String nombre;
  final VoidCallback onTap;

  const _CategoriaChip({required this.nombre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4B896)),
          boxShadow: const [
            BoxShadow(color: Color(0x11B8956A), blurRadius: 6)
          ],
        ),
        child: Text(
          nombre,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8a6840),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}