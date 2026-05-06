import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../utils/theme.dart';
import '../utils/loading_overlay.dart';
import '../services/database_service.dart';

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
