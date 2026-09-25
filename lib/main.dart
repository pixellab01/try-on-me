import 'package:flutter/material.dart';
import 'config.dart';
import 'screens/onboarding.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const TryOnMeApp());
}

class TryOnMeApp extends StatelessWidget {
  const TryOnMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Try On Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: AppConfig.onboarded ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
