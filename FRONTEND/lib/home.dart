import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/predict_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'utils/theme.dart';
import 'utils/loading_overlay.dart';
import 'dart:ui';
import 'widgets/bouncing_button.dart';

import 'chat.dart';
import 'medication.dart';
import 'profile.dart';
import 'scan_reports.dart';
import 'schedule.dart';
import 'patients/patient_list.dart';
import 'widgets/vita_shade_guide.dart';
import 'admin/admin_dashboard.dart';
import 'appointments/appointments_screen.dart';
import 'services/user_service.dart';
import 'utils/role_provider.dart';
import 'services/ai_recommendation_service.dart';
import 'services/database_service.dart';

import 'widgets/camera_view.dart';
import 'screens/history_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CameraView(),           // 0: Camera (Home)
      const PatientListScreen(),    // 1: Patients
      const GlobalHistoryScreen(),  // 2: History
      const AppointmentsScreen(),   // 3: Schedule
      const ProfileScreen(),        // 4: Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Active Screen
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Premium Bottom Nav
          if (!isKeyboardOpen)
            Positioned(
              bottom: 25,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.camera_rounded, 'Scan')),
                        Expanded(child: _buildNavItem(1, Icons.people_rounded, 'Patients')),
                        Expanded(child: _buildNavItem(2, Icons.history_rounded, 'History')),
                        Expanded(child: _buildNavItem(3, Icons.calendar_today_rounded, 'Schedule')),
                        Expanded(child: _buildNavItem(4, Icons.person_rounded, 'Profile')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return BouncingButton(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      scaleFactor: 0.85,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? AppTheme.accent : Colors.white60,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accent : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
