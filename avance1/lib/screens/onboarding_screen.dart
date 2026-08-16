import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;
  Timer? _timer;

  final Color _cafe = const Color(0xFFB8956A);

  // Cada slide: imagen de fondo + titulo + texto
  final List<Map<String, String>> _slides = [
    {
      'fondo': 'assets/onboarding/fondo1.jpg',
      'titulo': 'Bienvenida a Find Your Self',
      'texto': 'Joyeria artesanal unica, pensada para vos. Descubri piezas hechas con amor y detalle.',
    },
    {
      'fondo': 'assets/onboarding/fondo2.jpg',
      'titulo': 'Encontra tu estilo',
      'texto': 'Explora el catalogo, busca por precio o categoria, y guarda tus joyas favoritas con un toque.',
    },
    {
      'fondo': 'assets/onboarding/fondo3.jpg',
      'titulo': 'Compra facil y segura',
      'texto': 'Paga con tarjeta, SINPE, PayPal o efectivo, y segui tu pedido desde la app. Tu tiempo, tu ritmo.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarAutoPaso();
  }

  // Pasa las pantallas solas cada 4 segundos; en la ultima se detiene
  void _iniciarAutoPaso() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_paginaActual < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel(); // llego a la ultima, deja de pasar solo
      }
    });
  }

  Future<void> _terminar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_visto', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esUltima = _paginaActual == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Fondos de imagen que cambian con cada slide
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _paginaActual = i);
              // si el usuario desliza a la ultima, cancela el auto-paso
              if (i == _slides.length - 1) _timer?.cancel();
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de fondo difuminada
                  Image.asset(slide['fondo']!, fit: BoxFit.cover),
                  // Capa oscura encima para que el texto se lea
                  Container(color: Colors.black.withOpacity(0.35)),
                  // Contenido
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            slide['titulo']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['texto']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 180),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Boton "Saltar" arriba a la derecha
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: TextButton(
                  onPressed: _terminar,
                  child: const Text('Saltar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),

          // Puntitos + boton abajo
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 32, right: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Puntitos indicadores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final activo = i == _paginaActual;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: activo ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activo ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // El boton "Empezar" solo aparece en la ultima pantalla
                    AnimatedOpacity(
                      opacity: esUltima ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: esUltima ? _terminar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cafe,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Empezar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}