import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../utils/theme.dart';
import '../utils/loading_overlay.dart';
import '../services/database_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'patient_detail.dart';
import '../widgets/bouncing_button.dart';

import 'patient_form.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterGender = 'All';

  @override
  void initState() {
    super.initState();
    _syncPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .collection('patients')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        await DatabaseService.saveLocal(DatabaseService.patientsBox, doc.id, data);
      }
      debugPrint("Synced ${snapshot.docs.length} patients to local storage.");
    } catch (e) {
      debugPrint("Patient sync failed: $e. Using local data.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          _buildPatientList(user?.uid ?? ''),
        ],
      ),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: false,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.premiumGradient),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'PATIENTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Clinical patient management',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search patients by name or phone...',
                hintStyle: AppTheme.subHeading.copyWith(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.secondaryText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Gender Filter Chips
          Row(
            children: ['All', 'Male', 'Female', 'Other'].map((g) {
              final isSelected = _filterGender == g;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filterGender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.secondaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(String doctorUid) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.patientsBox).listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        final patients = box.values
            .map((data) => PatientModel.fromFirestore(
                _FakeDocumentSnapshot(data['patientId'], Map<String, dynamic>.from(data))))
            .where((p) {
          if (p.isArchived) return false;
          final matchesSearch = _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery) ||
              p.phone.contains(_searchQuery);
          final matchesGender =
              _filterGender == 'All' || p.gender == _filterGender;
          return matchesSearch && matchesGender;
        }).toList();

        // Sort by name locally
        patients.sort((a, b) => a.name.compareTo(b.name));

        if (patients.isEmpty) {
          return SliverToBoxAdapter(child: _buildNoResultsState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPatientCard(patients[index]),
              childCount: patients.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return BouncingButton(
      scaleFactor: 0.96,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  gradient: AppTheme.premiumGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    patient.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (patient.hasMedicalFlags) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '⚠ FLAGS',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.age} yrs · ${patient.gender} · ${patient.phone}',
                      style: AppTheme.subHeading.copyWith(fontSize: 13),
                    ),
                    if (patient.lastVisitDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last visit: ${DateFormat('MMM dd, yyyy').format(patient.lastVisitDate!)}',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncingButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientFormScreen(patient: patient),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BouncingButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _confirmDelete(patient);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PatientModel patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
        content: Text('Are you sure you want to delete ${patient.name}? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box(DatabaseService.patientsBox);
      await box.delete(patient.patientId);
      
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('clinics')
              .doc(user.uid)
              .collection('patients')
              .doc(patient.patientId)
              .delete();
        }
      } catch (e) {
        debugPrint("Remote delete error: $e");
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.premiumGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Patients Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first patient to begin\nyour clinical workflow',
            textAlign: TextAlign.center,
            style: AppTheme.subHeading.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.secondaryText),
          const SizedBox(height: 16),
          const Text(
            'No Results Found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search query or filter',
            style: AppTheme.subHeading.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90.0), // Raise above BottomNav
      child: Container(
        height: 64,
        width: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.accentShadow,
      ),
      child: IconButton(
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
        onPressed: () => _showAddPatientSheet(context),
      ),
      ),
    );
  }

  void _showAddPatientSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
  }
}

// ─── Skeleton Loading ─────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: List.generate(6, (i) => _SkeletonCard()),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppTheme.background,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 140, decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(7))),
                  const SizedBox(height: 8),
                  Container(height: 11, width: 100, decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Patient form screen (referenced above)
class PatientFormScreen extends StatefulWidget {
  final PatientModel? patient;
  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _allergyController = TextEditingController();
  final _medHistoryController = TextEditingController();
  final _medicationsController = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      final p = widget.patient!;
      _nameController.text = p.name;
      _phoneController.text = p.phone;
      _emailController.text = p.email ?? '';
      _addressController.text = p.address ?? '';
      _allergyController.text = p.allergies ?? '';
      _medHistoryController.text = p.medicalHistory ?? '';
      _medicationsController.text = p.medications ?? '';
      _dob = p.dateOfBirth;
      _gender = p.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _allergyController.dispose();
    _medHistoryController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date of birth'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final patientId = widget.patient?.patientId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      final patientData = {
        'patientId': patientId,
        'clinicId': user.uid,
        'name': _nameController.text.trim(),
        'dateOfBirth': _dob!.toIso8601String(),
        'gender': _gender,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'allergies': _allergyController.text.trim(),
        'medicalHistory': _medHistoryController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'assignedDoctorUid': user.uid,
        'totalVisits': widget.patient?.totalVisits ?? 0,
        'createdAt': widget.patient == null
            ? DateTime.now().toIso8601String()
            : widget.patient!.createdAt.toIso8601String(),
        'isArchived': false,
      };

      await DatabaseService.saveLocal(DatabaseService.patientsBox, patientId, patientData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.patient == null ? 'Patient added successfully' : 'Patient updated'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.patient == null ? 'NEW PATIENT' : 'EDIT PATIENT',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('SAVE', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Personal Information'),
                  _buildField(_nameController, 'Full Name', Icons.person_outline_rounded, required: true),
                  _buildDOBPicker(),
                  _buildGenderPicker(),
                  _buildField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone, required: true),
                  _buildField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _buildField(_addressController, 'Home Address', Icons.home_outlined, maxLines: 2),
                  const SizedBox(height: 24),
                  _sectionTitle('Medical Information'),
                  _buildField(_allergyController, 'Allergies', Icons.warning_amber_rounded, maxLines: 2),
                  _buildField(_medHistoryController, 'Medical History', Icons.history_edu_rounded, maxLines: 3),
                  _buildField(_medicationsController, 'Current Medications', Icons.medication_outlined, maxLines: 2),
                ],
              ),
            ),
          ),
          if (_isSaving) const PremiumLoadingOverlay(message: 'Saving Patient', subMessage: 'Updating clinical records'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: AppTheme.secondaryText,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red, width: 2)),
        ),
      ),
    );
  }

  Widget _buildDOBPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dob ?? DateTime(1990),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: AppTheme.accent),
              ),
              child: child!,
            ),
          );
          if (picked != null) setState(() => _dob = picked);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, color: AppTheme.accent, size: 20),
              const SizedBox(width: 12),
              Text(
                _dob == null
                    ? 'Date of Birth'
                    : DateFormat('MMMM dd, yyyy').format(_dob!),
                style: TextStyle(
                  color: _dob == null ? AppTheme.secondaryText : AppTheme.primary,
                  fontWeight: _dob == null ? FontWeight.normal : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: ['Male', 'Female', 'Other'].map((g) {
          final selected = _gender == g;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    g,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Helper for Hive to PatientModel conversion
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
