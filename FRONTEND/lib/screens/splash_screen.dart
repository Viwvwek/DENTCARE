import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import '../firebase_options.dart';
import '../utils/theme.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../utils/globals.dart';
import '../utils/role_provider.dart';
import '../home.dart';
import '../getstart.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _initError = false;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      cameras = await availableCameras();
      await dotenv.load(fileName: ".env");

      await Hive.initFlutter();
      await DatabaseService.init();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      NotificationService.init().catchError((e) {
        debugPrint("NotificationService initialization failed: $e");
      });

      // Minimum artificial delay to let the animation play and feel premium
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: const AuthWrapper(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Initialization Error:\n$_errorMsg",
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.premiumGradient)),
          
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withValues(alpha: 0.05)),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.accentShadow,
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 50),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "DENTCARE",
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Precision in Every Shade",
                          style: TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Scaffold(
            key: ValueKey('waiting'),
            backgroundColor: AppTheme.primary,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          UserService.ensureUserDocument(snapshot.data!);
          child = const RoleProviderWrapper(key: ValueKey('home'), child: Home());
        } else {
          child = const Getstart(key: ValueKey('getstart'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCirc,
          switchOutCurve: Curves.easeInCirc,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}
