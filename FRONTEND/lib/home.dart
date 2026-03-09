import 'package:flutter/foundation.dart';
import 'services/predict_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat.dart';
import 'medication.dart';
import 'profile.dart';
import 'scan_reports.dart';
import 'schedule.dart';

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
  bool _isLoading = false;

  final List<Widget> _screens = [
    // We will build the home content down below
    const ScheduleScreen(),   // Index 0 replaces placeholder
    const ChatScreen(),       // Index 1
    const SizedBox.shrink(), // Index 2 is the 'Add' button action (dialog)
    const MedicationScreen(), // Index 3
    const ProfileScreen(),    // Index 4
  ];

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture with Camera'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screens[0] = _buildHomeContent();
    
    // Check if the software keyboard is open
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF38B2AC), // Set scaffold background to match gradient bottom
      body: SafeArea(
        child: Stack(
          children: [
          // The actively selected screen
          _screens[_currentIndex],

          // 3. Floating Bottom Navigation Bar (Hide when typing)
          if (!isKeyboardOpen)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF4FD1C5).withOpacity(0.9), // Solidified background slightly for visibility over other screens
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 0),
                    child: Icon(Icons.home_filled, color: _currentIndex == 0 ? Colors.white : Colors.white60, size: 30),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Icon(Icons.chat_bubble_outline,
                        color: _currentIndex == 1 ? Colors.white : Colors.white60, size: 28),
                  ),
                  // Add Button Circle
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                          color: const Color(0xFF38B2AC),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ]),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 3),
                    child: Icon(Icons.medication_outlined,
                        color: _currentIndex == 3 ? Colors.white : Colors.white60, size: 28),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 4),
                    child: Icon(Icons.person_outline,
                        color: _currentIndex == 4 ? Colors.white : Colors.white60, size: 30),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
     ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4FD1C5), // Top Teal
                  Color(0xFF38B2AC), // Bottom Teal
                ],
              ),
            ),
          ),

          // 2. Scrollable Content
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Ensures it doesn't stretch too far on tablets/web
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 40, bottom: 100), // Bottom padding for nav bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "DentCare Portal", 
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Hello, ${FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Doctor'}",
                              style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "Explore checkups",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Search Icon Box
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Search functionality coming soon!')),
                            );
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Icon(Icons.search,
                                color: Colors.white, size: 28),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ WEB image preview
                  if (_webImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          _webImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

// ✅ MOBILE / DESKTOP image preview
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  if ((_webImage != null || _selectedImage != null))
                    const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  if (_predictedShade != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Predicted Shade: $_predictedShade",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- Checkup Cards Area (Staggered Layout) ---
                  // We use a Row with two Columns to create the staggered (diagonal) effect
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Scan Report)
                        Expanded(
                          child: Column(
                            children: [
                              _buildCheckupCard(
                                title: "Scan Report",
                                duration: "50 minutes",
                                imagePath:
                                    "assets/images/clipboard_3d.png", // Replace with your asset
                                icon: Icons.paste_outlined, // Fallback icon
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanReportsScreen()));
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column (Shade Analysis) - Pushed down using SizedBox
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(
                                  height: 60), // Pushes the second card down
                              _buildCheckupCard(
                                title: "Shade analysis",
                                duration: "50 minutes",
                                imagePath:
                                    "assets/images/microscope_3d.png", // Replace with your asset
                                icon: Icons.biotech_outlined, // Fallback icon
                                onTap: _pickFromGallery,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Last Scan Section ---
                  const Padding(
                    padding: EdgeInsets.only(left: 24.0, bottom: 15),
                    child: Text(
                      "Recent Scans",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Dynamic Scan List from Firestore (Filtered for the current user)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('scans')
                          .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                          .orderBy('timestamp', descending: true)
                          .limit(3)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SelectableText(
                              'Firestore Index Required:\n\n${snapshot.error}\n\nPlease copy the URL in the error above and open it in your browser to generate the database index.',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                "No recent scans available.",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final email = data['doctorEmail'] ?? 'Unknown';
                            final shade = data['shade'] ?? 'Unknown';
                            final timestamp = data['timestamp'] as Timestamp?;
                            
                            String timeString = "Recently";
                            if (timestamp != null) {
                              final date = timestamp.toDate();
                              timeString = "${date.month}/${date.day}/${date.year}";
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: _buildDoctorCard(email, shade, timeString),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Future<void> _predictShade() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PredictService.predictImage(_selectedImage!);
      final shade = result['shade'];
      final confidence = result['confidence'];

      setState(() {
        _predictedShade = shade;
        _confidence = confidence;
      });

      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && shade != null) {
        try {
          await FirebaseFirestore.instance.collection('scans').add({
            'doctorEmail': user.email ?? 'Unknown Doctor',
            'shade': shade,
            'confidence': confidence,
            'timestamp': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 10));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scan saved to cloud successfully!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          debugPrint("Firestore write error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: Could not save to cloud. Check Firestore database rules! Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

    } catch (e) {
      debugPrint("Prediction error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze scan. Is the ML backend running? Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper Widget for the 3D Checkup Cards
  Widget _buildCheckupCard({
    required String title,
    required String duration,
    required String imagePath,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 220, // Total height for stack
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background Card
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // Clearer, more professional glass effect
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
            ),
            // White Info Box
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            duration,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Floating 3D Image (Positioned at top)
            Positioned(
              top: 0,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.white.withOpacity(0.3), // Light glow behind image
                ),
                child: Center(
                  // Replace this Icon with Image.asset(imagePath) when you have images
                  child: Icon(icon, size: 80, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Doctor List Tile
  Widget _buildDoctorCard(String doctorEmail, String shade, String timeString) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF81E6D9).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_information, color: Color(0xFF38B2AC)),
          ),
          const SizedBox(width: 15),
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Scanned by: $doctorEmail",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Shade: $shade",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38B2AC),
                  ),
                ),
                Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
