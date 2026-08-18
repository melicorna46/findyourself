import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

// Pantalla que decide que mostrar al abrir la app:
// - Primera vez  -> onboarding
// - Siguientes veces -> login directo
class InicioDecision extends StatefulWidget {
  const InicioDecision({super.key});

  @override
  State<InicioDecision> createState() => _InicioDecisionState();
}

class _InicioDecisionState extends State<InicioDecision> {
  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    final prefs = await SharedPreferences.getInstance();
    final yaVioOnboarding = prefs.getBool('onboarding_visto') ?? false;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => yaVioOnboarding ? const LoginScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga breve mientras decide (muestra el logo)
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond_outlined, size: 70, color: const Color(0xFF8a6840)),
            const SizedBox(height: 16),
            const Text(
              'Find Your Self',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8a6840),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFFB8956A)),
          ],
        ),
      ),
    );
  }
}