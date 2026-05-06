import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DentCare Premium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.accent),
        useMaterial3: true,
      ),
      home: const AnimatedSplashScreen(),
    );
  }
}
