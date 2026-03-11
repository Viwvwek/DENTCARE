import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'utils/theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)), child: child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _addAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDate == null || _selectedTime == null) return;

    final scheduledDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorEmail': user.email,
        'patientName': _patientController.text.trim(),
        'reason': _reasonController.text.trim(),
        'scheduledTime': scheduledDateTime,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showAddAppointmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("BOOK APPOINTMENT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18, color: AppTheme.primary)),
                const SizedBox(height: 25),
                _buildField(_patientController, "Patient Name", Icons.person_outline),
                const SizedBox(height: 15),
                _buildField(_reasonController, "Procedure Reason", Icons.medical_services_outlined),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerButton(
                        icon: Icons.calendar_today_rounded,
                        label: _selectedDate == null ? "Select Date" : DateFormat('MMM dd').format(_selectedDate!),
                        onTap: () async { await _pickDate(); setModalState(() {}); },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildPickerButton(
                        icon: Icons.access_time_rounded,
                        label: _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                        onTap: () async { await _pickTime(); setModalState(() {}); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _addAppointment,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text("CONFIRM SCHEDULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.accent),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("SCHEDULE PORTAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.primary, fontSize: 16)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today, color: AppTheme.primary), onPressed: () => _showAddAppointmentDialog()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('scheduledTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No upcoming sessions."));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildAppointmentCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data) {
    final timestamp = data['scheduledTime'] as Timestamp?;
    final d = timestamp?.toDate();
    final dateStr = d != null ? DateFormat('MMM dd').format(d) : "TBA";
    final timeStr = d != null ? DateFormat('jm').format(d) : "TBA";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: AppTheme.softShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Text(dateStr.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                Text(timeStr, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['patientName'], style: AppTheme.cardTitle),
                Text(data['reason'], style: AppTheme.subHeading.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
