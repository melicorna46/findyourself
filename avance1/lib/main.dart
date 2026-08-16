import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/carrito_screen.dart';
import 'screens/contacto_screen.dart';
import 'screens/favoritos_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/login_screen.dart';
import 'screens/inicio_decision.dart';

void main() {
  runApp(const FindYourselfApp());
}

class FindYourselfApp extends StatelessWidget {
  const FindYourselfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Your Self',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8956A)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
      ),
      home: const InicioDecision(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _cantidadCarrito = 0;

  void actualizarCarrito(int cantidad) {
    setState(() => _cantidadCarrito = cantidad);
  }

  void navegarA(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavegar: navegarA),
      const CatalogoScreen(),
      CarritoScreen(onActualizar: actualizarCarrito),
      const FavoritosScreen(),
      const HistorialScreen(),
      const ContactoScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFFFAF6F0),
        indicatorColor: const Color(0xFFD4B896),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF7a6150)),
            selectedIcon: Icon(Icons.home, color: Color(0xFF8a6840)),
            label: 'Inicio',
          ),
            const NavigationDestination(
            icon: Icon(Icons.local_offer_outlined, color: Color(0xFF7a6150)),
            selectedIcon: Icon(Icons.local_offer, color: Color(0xFF8a6840)),
            label: 'Catalogo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _cantidadCarrito > 0,
              label: Text('$_cantidadCarrito'),
              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF7a6150)),
            ),
            selectedIcon: Badge(
              isLabelVisible: _cantidadCarrito > 0,
              label: Text('$_cantidadCarrito'),
              child: const Icon(Icons.shopping_bag, color: Color(0xFF8a6840)),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border, color: Color(0xFF7a6150)),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFF8a6840)),
            label: 'Favoritos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF7a6150)),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF8a6840)),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.mail_outline, color: Color(0xFF7a6150)),
            selectedIcon: Icon(Icons.mail, color: Color(0xFF8a6840)),
            label: 'Contacto',
          ),
        ],
      ),
    );
  }
}