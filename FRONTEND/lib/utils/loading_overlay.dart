import 'package:flutter/material.dart';
import 'dart:ui';
import 'theme.dart';

class PremiumLoadingOverlay extends StatelessWidget {
  final String message;
  final String subMessage;

  const PremiumLoadingOverlay({
    super.key,
    this.message = "AI ANALYZING",
    this.subMessage = "Detecting shades with precision",
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                    strokeWidth: 5,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  message.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subMessage,
                  style: AppTheme.subHeading.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
