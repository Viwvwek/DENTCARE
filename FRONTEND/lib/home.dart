import 'package:flutter/foundation.dart';
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  File? _selectedImage;
  Uint8List? _webImage;
  String? _predictedShade;
  double? _confidence;
  String? _treatmentRecommendation;
  bool _isLoading = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      Container(),                // 0: Home (built dynamically)
      const PatientListScreen(),  // 1: Patients
      const ChatScreen(),         // 2: DentBot
      const SizedBox.shrink(),    // 3: Scan (CTA)
      const AppointmentsScreen(), // 4: Appointments
      const RoleGuard(
        allowedRoles: [AppRole.admin],
        featureName: 'Admin Dashboard',
        child: AdminDashboardScreen(),
      ), // 5: Admin
      const MedicationScreen(),   // 6: Medications
      const ProfileScreen(),      // 7: Profile
    ];
  }

  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        await _predictShade();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _webImage = null;
          });
        }
        await _predictShade();
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.accent),
                ),
                title: const Text('Upload from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.accent),
                ),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Active Screen
          _currentIndex == 0
              ? _buildHomeContent()
              : (_currentIndex < _screens.length ? _screens[_currentIndex] : _screens[_screens.length - 1]),

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
                        _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
                        _buildNavItem(1, Icons.people_rounded, 'Patients'),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.accentShadow,
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        _buildNavItem(4, Icons.calendar_today_rounded, 'Schedule'),
                        _buildNavItem(7, Icons.person_rounded, 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading Overlay
          if (_isLoading) const PremiumLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, [String? label]) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppTheme.accent : Colors.white60, size: 24),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: isSelected ? AppTheme.accent : Colors.white60, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final user = FirebaseAuth.instance.currentUser;
    final String name = user?.email?.split('@').first ?? 'Doctor';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header Section
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  image: DecorationImage(
                    image: AssetImage('assets/images/hero_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        AppTheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DentCare Premium",
                      style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome back,\nDr. ${name.toUpperCase()}",
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Prediction Result Box (If any)
          if (_predictedShade != null && !_isLoading)
            _buildResultCard(),

          // Quick Action Cards - 2x2 grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildPremiumActionCard("Patients", "Manage Records", Icons.people_rounded, AppTheme.primary,
                    () => setState(() => _currentIndex = 1)),
                _buildPremiumActionCard("Schedule", "Appointments", Icons.calendar_today_rounded, const Color(0xFF6366F1),
                    () => setState(() => _currentIndex = 4)),
                _buildPremiumActionCard("AI Scan", "Shade Analysis", Icons.document_scanner_rounded, AppTheme.accent,
                    _pickFromGallery),
                _buildPremiumActionCard("Dashboard", "Clinic Analytics", Icons.bar_chart_rounded, const Color(0xFFF59E0B),
                    () => setState(() => _currentIndex = 5)),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // Recent Activity Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Recent Activity", style: AppTheme.heading),
                Text("View All", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recent Scans List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildRecentScansList(),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPremiumActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.subHeading.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Column(
        children: [
          // Compact result header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.premiumGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AI Analysis Complete", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("SHADE: $_predictedShade", style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Text("${(_confidence! * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // VITA Shade Guide
          VitaShadeGuideWidget(predictedShade: _predictedShade!, confidence: _confidence!),
          
          if (_treatmentRecommendation != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("AI Clinical Recommendation", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_treatmentRecommendation!, style: const TextStyle(fontSize: 12, height: 1.5, color: AppTheme.secondaryText)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentScansList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('scans')
          .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No scans found", style: AppTheme.subHeading));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tooth Shade Scan", style: AppTheme.cardTitle.copyWith(fontSize: 16)),
                      Text("Result: ${data['shade']}", style: AppTheme.subHeading.copyWith(fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _predictShade() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);

    try {
      File finalImage = _selectedImage!;
      if (!kIsWeb) {
        final filePath = _selectedImage!.absolute.path;
        final lastIndex = filePath.lastIndexOf(RegExp(r'.jp|.pn'));
        final splitted = filePath.substring(0, (lastIndex));
        final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          _selectedImage!.absolute.path,
          outPath,
          quality: 70,
          minWidth: 512,
          minHeight: 512,
        );
        if (compressedFile != null) finalImage = File(compressedFile.path);
      }

      final result = await PredictService.predictImage(finalImage);
      final shade = result['shade'];
      final conf = result['confidence'];

      // Generate AI recommendation
      final recommendation = await AIRecommendationService.generateTreatmentRecommendation(
        predictedShade: shade,
        confidence: conf,
      );

      setState(() {
        _predictedShade = shade;
        _confidence = conf;
        _treatmentRecommendation = recommendation;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await UserService.getCurrentProfile();
        final clinicId = profile?.clinicId ?? user.uid;
        final scanId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final scanData = {
          'id': scanId,
          'clinicId': clinicId,
          'doctorUid': user.uid,
          'doctorName': profile?.displayName ?? user.email?.split('@').first ?? 'Doctor',
          'doctorEmail': user.email,
          'shade': shade,
          'confidence': conf,
          'treatmentRecommendation': recommendation,
          'isLowConfidence': conf < 0.75,
          'timestamp': DateTime.now().toIso8601String(), // Use ISO string for Hive
        };

        // Save locally and queue for Firestore sync
        await DatabaseService.saveLocal(DatabaseService.scansBox, scanId, scanData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processing Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
