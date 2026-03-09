import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4FD1C5),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4FD1C5),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }
  }

  Future<void> _addAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_patientController.text.trim().isEmpty || _reasonController.text.trim().isEmpty || _selectedDate == null || _selectedTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields, date, and time.')),
       );
       return;
    }

    // Combine date and time
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorEmail': user.email ?? 'Unknown Doctor',
        'patientName': _patientController.text.trim(),
        'reason': _reasonController.text.trim(),
        'scheduledTime': scheduledDateTime,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _patientController.clear();
      _reasonController.clear();
      if (mounted) {
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder so pickers can trigger UI updates purely within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Book Appointment', style: TextStyle(color: Color(0xFF4FD1C5), fontWeight: FontWeight.bold)),
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
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason (e.g., Routine Checkup)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Date Picker Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.black87,
                         elevation: 0,
                         side: const BorderSide(color: Colors.grey, width: 0.5),
                         minimumSize: const Size(double.infinity, 50),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF4FD1C5)),
                      label: Text(_selectedDate == null 
                          ? 'Select Date' 
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                      onPressed: () async {
                        await _pickDate();
                        setDialogState(() {}); // Refresh dialog
                      },
                    ),
                    const SizedBox(height: 10),
                    // Time Picker Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.black87,
                         elevation: 0,
                         side: const BorderSide(color: Colors.grey, width: 0.5),
                         minimumSize: const Size(double.infinity, 50),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      icon: const Icon(Icons.access_time, color: Color(0xFF4FD1C5)),
                      label: Text(_selectedTime == null 
                          ? 'Select Time' 
                          : _selectedTime!.format(context)),
                      onPressed: () async {
                        await _pickTime();
                        setDialogState(() {}); // Refresh dialog
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _patientController.clear();
                    _reasonController.clear();
                    _selectedDate = null;
                    _selectedTime = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _addAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD1C5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _updateStatus(String docId, String currentStatus) async {
    String newStatus = currentStatus == 'PENDING' ? 'COMPLETED' : 'PENDING';
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
        'status': newStatus
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      case 'PENDING':
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4FD1C5),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('scheduledTime', descending: false) // Order chronologically (soonest first)
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
                  'Firestore Index Required for Appointments:\n\n${snapshot.error}\n\nPlease copy the URL in the error above and open it in your browser to generate the database index.',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.event_available, size: 80, color: Colors.black12),
                   SizedBox(height: 16),
                   Text(
                    'No upcoming appointments.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 100.0), // Space for nav bar
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final patient = data['patientName'] ?? 'Unknown Patient';
              final reason = data['reason'] ?? 'General Visit';
              final status = data['status'] ?? 'PENDING';
              final timestamp = data['scheduledTime'] as Timestamp?;
              
              String dateString = "TBA";
              String timeString = "TBA";
              if (timestamp != null) {
                final d = timestamp.toDate();
                dateString = DateFormat('MMM dd, yyyy').format(d);
                timeString = DateFormat('jm').format(d); // e.g., 5:08 PM
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Time Date Block on the Left
                      Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FFFA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(dateString.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38B2AC))), // MMM
                            Text(dateString.split(' ')[1].replaceAll(',', ''), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF38B2AC))), // dd
                            const SizedBox(height: 4),
                            Text(timeString, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Appointment Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(reason, style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 8),
                            // Status Badge
                            GestureDetector(
                               onTap: () => _updateStatus(doc.id, status),
                               child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                                ),
                                child: Text(
                                  status, 
                                  style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                               ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Padding to lift above standard navbar bounds
        child: FloatingActionButton.extended(
          onPressed: _showAddAppointmentDialog,
          backgroundColor: const Color(0xFF38B2AC),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Book Appt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
