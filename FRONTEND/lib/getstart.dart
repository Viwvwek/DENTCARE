import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dentcare/login.dart';
import 'utils/theme.dart';
import 'widgets/bouncing_button.dart';
import 'dart:ui';

class Getstart extends StatelessWidget {
  const Getstart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Background Gradient & Abstract Hero
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.premiumGradient,
            ),
          ),
          
          // Floating 3D Elements Area
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  // App Branding
                  Row(
                    children: [
                      Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.accentShadow,
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "DENTCARE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Hero Image
                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/icons_3d.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Tagline
                  const Text(
                    "Precision in\nEvery Shade",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42, // Reduced slightly to fit more screens
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "The world's most advanced AI-driven dental shade analysis system for elite clincians.",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                  // Get Started Button
                  BouncingButton(
                    scaleFactor: 0.95,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
                    },
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ENTER PORTAL",
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
