import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    if (patientName.isEmpty || medName.isEmpty || instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      if (docId == null) {
        // Create new
        await FirebaseFirestore.instance.collection('medications').add({
          'doctorEmail': user.email ?? 'Unknown Doctor',
          'patientName': patientName,
          'medicationName': medName,
          'instructions': instructions,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing
        await FirebaseFirestore.instance.collection('medications').doc(docId).update({
          'patientName': patientName,
          'medicationName': medName,
          'instructions': instructions,
        });
      }
      
      _patientController.clear();
      _medController.clear();
      _instructionsController.clear();
      
      if (mounted) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docId == null ? 'Medication added!' : 'Medication updated!'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medication: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMedicationDialog({String? docId, Map<String, dynamic>? currentData}) {
    if (docId != null && currentData != null) {
      _patientController.text = currentData['patientName'] ?? '';
      _medController.text = currentData['medicationName'] ?? '';
      _instructionsController.text = currentData['instructions'] ?? '';
    } else {
      _patientController.clear();
      _medController.clear();
      _instructionsController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Prescription' : 'Edit Prescription', 
            style: const TextStyle(color: Color(0xFF4FD1C5))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _patientController,
                decoration: InputDecoration(
                  labelText: 'Patient Name',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _medController,
                decoration: InputDecoration(
                  labelText: 'Medication Name (e.g. Amoxicillin)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Instructions (e.g. 1 pill every 8 hrs)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _saveMedication(docId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FD1C5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('medications').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication removed'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing medication: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4FD1C5),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medications')
            .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4FD1C5)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  'Firestore Index Required:\n\n${snapshot.error}\n\nPlease copy the URL in the error above and open it in your browser to generate the database index.',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.medication, size: 80, color: Colors.black12),
                   SizedBox(height: 16),
                   Text(
                    'No active prescriptions found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 100.0), // Padding for FloatingNavBar
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final patient = data['patientName'] ?? 'Unknown Patient';
              final med = data['medicationName'] ?? 'Unknown Medication';
              final instructions = data['instructions'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              
              String dateString = "Recently";
              if (timestamp != null) {
                final d = timestamp.toDate();
                dateString = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vaccines, color: Color(0xFF38B2AC)),
                  ),
                  title: Text(
                    patient,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(med, style: const TextStyle(color: Color(0xFF38B2AC), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(instructions, style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text('Prescribed: $dateString', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                        tooltip: 'Edit Prescription',
                        onPressed: () => _showMedicationDialog(docId: doc.id, currentData: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Mark Completed',
                        onPressed: () => _deleteMedication(doc.id),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Padding to lift above standard navbar bounds
        child: FloatingActionButton.extended(
          onPressed: () => _showMedicationDialog(),
          backgroundColor: const Color(0xFF38B2AC),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New Prescript", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
