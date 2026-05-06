import 'package:flutter/material.dart';
import 'dart:io';
import '../models/patient_model.dart';
import '../utils/theme.dart';
import '../services/predict_service.dart';
import '../services/ai_recommendation_service.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/vita_shade_guide.dart';
import '../utils/loading_overlay.dart';
import 'package:intl/intl.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final PatientModel? patient;

  const ResultScreen({super.key, required this.imageFile, this.patient});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? _predictedShade;
  double? _confidence;
  String? _insight;
  bool _isProcessing = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // 1. TFLite Prediction (Local)
      final result = await PredictService.predictImage(widget.imageFile);
      if (mounted) {
        setState(() {
          _predictedShade = result['shade'];
          _confidence = result['confidence'];
        });
      }

      // 2. Gemini Clinical Insight (Cloud)
      final insight = await AIRecommendationService.generateTreatmentRecommendation(
        predictedShade: _predictedShade!,
        confidence: _confidence!,
      );

      if (mounted) {
        setState(() {
          _insight = insight;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Processing error: $e');
      if (mounted) {
        setState(() {
          _insight = "Clinical insight unavailable (Offline).";
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveScan() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final scanData = {
        'id': scanId,
        'patientId': widget.patient?.patientId,
        'patientName': (widget.patient?.name != null && widget.patient!.name.isNotEmpty) 
            ? widget.patient!.name 
            : 'Unassigned',
        'doctorUid': user.uid,
        'doctorEmail': user.email,
        'shade': _predictedShade,
        'confidence': _confidence,
        'insight': _insight,
        'timestamp': DateTime.now().toIso8601String(),
        'imagePath': widget.imageFile.path,
      };

      await DatabaseService.saveLocal(DatabaseService.scansBox, scanId, scanData);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan saved successfully'), backgroundColor: AppTheme.accent),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_predictedShade != null) _buildResultCard(),
                      const SizedBox(height: 24),
                      _buildInsightSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving) const PremiumLoadingOverlay(message: 'Syncing Scan', subMessage: 'Storing clinical data locally'),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'captured_image',
          child: Image.file(widget.imageFile, fit: BoxFit.cover),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOOTH SHADE", style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  Text(_predictedShade!, style: const TextStyle(color: AppTheme.primary, fontSize: 42, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text("${((_confidence ?? 0) * 100).toStringAsFixed(1)}%", style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 18)),
                    const Text("CONFIDENCE", style: TextStyle(color: AppTheme.accent, fontSize: 8, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          VitaShadeGuideWidget(predictedShade: _predictedShade!, confidence: _confidence ?? 0),
        ],
      ),
    );
  }

  Widget _buildInsightSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.premiumGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.accentShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 24),
              const SizedBox(width: 12),
              const Text("CLINICAL INSIGHT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const LinearProgressIndicator(backgroundColor: Colors.white10, color: AppTheme.accent)
          else
            Text(
              _insight ?? "Analyzing clinical data...",
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildPrimaryAction(
          label: 'SAVE & SYNC SCAN',
          icon: Icons.cloud_done_rounded,
          onTap: _saveScan,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryAction(
                label: 'SCHEDULE',
                icon: Icons.calendar_today_rounded,
                onTap: () {
                  // Navigate to schedule tab or show booking sheet
                  Navigator.pop(context); // Go back to camera
                  // Since we are in a stack, we'd need a better way to switch tabs.
                  // For now, let's just show a snackbar or booking sheet.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment scheduling available in Schedule tab'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryAction(
                label: 'ADD NOTES',
                icon: Icons.edit_note_rounded,
                onTap: () {
                  _showNotesDialog();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSecondaryAction(
          label: 'RE-SCAN TOOTH',
          icon: Icons.refresh_rounded,
          onTap: () => Navigator.pop(context),
          fullWidth: true,
        ),
      ],
    );
  }

  void _showNotesDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Clinical Notes', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter observations or patient history...',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() => _insight = "${_insight ?? ''}\n\nNotes: ${noteController.text}");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({required String label, required IconData icon, required VoidCallback onTap, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({required String label, required IconData icon, required VoidCallback onTap, bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 60,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
