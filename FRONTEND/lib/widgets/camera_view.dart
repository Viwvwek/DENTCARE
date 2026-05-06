import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/globals.dart';
import '../utils/theme.dart';
import '../models/patient_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../screens/result_screen.dart';
import '../patients/patient_form.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'bouncing_button.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final ImagePicker _picker = ImagePicker();

  CameraController? _controller;
  bool _isInitialized = false;
  PatientModel? _selectedPatient;
  bool _isCapturing = false;
  bool _isPicking = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;
    
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _flashMode = FlashMode.off;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageFile: File(photo.path),
              patient: _selectedPatient,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Viewfinder Overlay
          _buildViewfinderOverlay(),

          // Top Controls: Patient Selector
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPatientSelector(),
                  _buildFlashControl(),
                ],
              ),
            ),
          ),

          // Bottom Controls: Action Bar
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildRealtimeHint(),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGalleryButton(),
                    _buildCaptureButton(),
                    _buildFlipButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            // Corner marks
            ...List.generate(4, (index) {
              return Positioned(
                top: (index == 0 || index == 1) ? -2 : null,
                bottom: (index == 2 || index == 3) ? -2 : null,
                left: (index == 0 || index == 2) ? -2 : null,
                right: (index == 1 || index == 3) ? -2 : null,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      top: (index == 0 || index == 1) ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
                      bottom: (index == 2 || index == 3) ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
                      left: (index == 0 || index == 2) ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
                      right: (index == 1 || index == 3) ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return GestureDetector(
      onTap: _showPatientPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              _selectedPatient?.name ?? 'Quick Scan (No Patient)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.off;
        break;
      default:
        newMode = FlashMode.off;
    }

    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  Widget _buildFlashControl() {
    IconData icon;
    Color color;

    switch (_flashMode) {
      case FlashMode.always:
        icon = Icons.flash_on_rounded;
        color = AppTheme.accent;
        break;
      case FlashMode.auto:
        icon = Icons.flash_auto_rounded;
        color = Colors.orangeAccent;
        break;
      case FlashMode.off:
      default:
        icon = Icons.flash_off_rounded;
        color = Colors.white;
        break;
    }

    return BouncingButton(
      scaleFactor: 0.8,
      onTap: _toggleFlash,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildRealtimeHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'ALIGNED: Optimal lighting detected',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return BouncingButton(
      scaleFactor: 0.88,
      onTap: () {
        HapticFeedback.heavyImpact();
        _capture();
      },
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
        ),
        child: Center(
          child: Container(
            height: 65,
            width: 65,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return BouncingButton(
      onTap: _pickFromGallery,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            const Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    
    print("GALLERY_PICK: Button clicked");
    await HapticFeedback.mediumImpact();
    
    setState(() => _isPicking = true);
    
    try {
      print("GALLERY_PICK: Opening gallery...");
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null && mounted) {
        print("GALLERY_PICK: Image selected: ${image.path}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              imageFile: File(image.path),
              patient: _selectedPatient,
            ),
          ),
        );
      } else if (image == null) {
        print("GALLERY_PICK: User cancelled");
      }
    } catch (e) {
      print("GALLERY_PICK: Error occurred: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Widget _buildFlipButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCamera,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 4),
              const Text('Flip', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCamera() async {
    if (cameras.length < 2) return;
    
    final lensDirection = _controller!.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.back) {
      newDescription = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    } else {
      newDescription = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    }

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      newDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera flip error: $e');
    }
  }

  void _showPatientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('SELECT PATIENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary, letterSpacing: 1.5)),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box(DatabaseService.patientsBox).listenable(),
                  builder: (context, Box box, _) {
                    final patients = box.isEmpty ? <PatientModel>[] : box.keys.map((key) {
                      final data = Map<String, dynamic>.from(box.get(key));
                      return PatientModel.fromFirestore(
                          _FakeDocumentSnapshot(key.toString(), data));
                    }).where((p) => !p.isArchived).toList();
                    
                    patients.sort((a, b) => a.name.compareTo(b.name));
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: patients.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: AppTheme.background, child: Icon(Icons.person_off_rounded, color: AppTheme.secondaryText)),
                            title: const Text('Quick Scan (No Patient)', style: TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              setState(() => _selectedPatient = null);
                              Navigator.pop(context);
                            },
                          );
                        }
                        if (index == 1) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.accent,
                              child: Icon(Icons.person_add_rounded, color: Colors.white),
                            ),
                            title: const Text('Add New Patient', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                            onTap: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PatientFormScreen()),
                              );
                            },
                          );
                        }
                        final patient = patients[index - 2];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accent.withOpacity(0.1),
                            child: Text(patient.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(patient.phone),
                          onTap: () {
                            setState(() => _selectedPatient = patient);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for Hive to PatientModel conversion (reused)
class _FakeDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  _FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic operator [](Object field) => _data?[field];
  @override
  bool get exists => _data != null;
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  DocumentReference get reference => throw UnimplementedError();
  @override
  dynamic get(Object field) => _data?[field];
}
