import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/theme.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _medController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  Future<void> _saveMedication(String? docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final patientName = _patientController.text.trim();
    final medName = _medController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (patientName.isEmpty || medName.isEmpty || instructions.isEmpty) return;

    try {
      if (docId == null) {
        await FirebaseFirestore.instance.collection('medications').add({
          'doctorEmail': user.email,
          'patientName': patientName,
          'medicationName': medName,
          'instructions': instructions,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('medications').doc(docId).update({
          'patientName': patientName,
          'medicationName': medName,
          'instructions': instructions,
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showMedicationDialog({String? docId, Map<String, dynamic>? currentData}) {
    if (docId != null && currentData != null) {
      _patientController.text = currentData['patientName'] ?? '';
      _medController.text = currentData['medicationName'] ?? '';
      _instructionsController.text = currentData['instructions'] ?? '';
    } else {
      _patientController.clear(); _medController.clear(); _instructionsController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("PRESCRIBE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18, color: AppTheme.primary)),
              const SizedBox(height: 25),
              _buildField(_patientController, "Patient Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildField(_medController, "Medication", Icons.medication_outlined),
              const SizedBox(height: 15),
              _buildField(_instructionsController, "Clinical Instructions", Icons.notes_rounded, maxLines: 3),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _saveMedication(docId),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text("FINALIZE PRESCRIPTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.accent),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("MEDICAL LOGS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.primary, fontSize: 16)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_box_rounded, color: AppTheme.primary), onPressed: () => _showMedicationDialog()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medications')
            .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No active prescriptions."));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildMedCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedCard(String id, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: AppTheme.softShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.primary.withOpacity(0.02),
              child: Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Text(data['patientName'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary)),
                  const Spacer(),
                  const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.medication_rounded, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['medicationName'], style: AppTheme.cardTitle),
                        Text(data['instructions'], style: AppTheme.subHeading.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
