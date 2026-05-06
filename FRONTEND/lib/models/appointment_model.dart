import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorUid;
  final String doctorName;
  final DateTime dateTime;
  final int durationMinutes;
  final String type; // 'scan', 'consultation', 'follow-up', 'emergency'
  final String status; // 'scheduled', 'confirmed', 'in-progress', 'completed', 'cancelled', 'no-show'
  final String? notes;
  final bool reminderSent;
  final String clinicId;

  AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorUid,
    required this.doctorName,
    required this.dateTime,
    required this.durationMinutes,
    required this.type,
    required this.status,
    this.notes,
    required this.reminderSent,
    required this.clinicId,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    return AppointmentModel(
      appointmentId: data['appointmentId'] ?? doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorUid: data['doctorUid'] ?? '',
      doctorName: data['doctorName'] ?? '',
      dateTime: parseDate(data['dateTime']),
      durationMinutes: data['durationMinutes'] ?? 30,
      type: data['type'] ?? 'consultation',
      status: data['status'] ?? 'scheduled',
      notes: data['notes'],
      reminderSent: data['reminderSent'] ?? false,
      clinicId: data['clinicId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'type': type,
      'status': status,
      'notes': notes,
      'reminderSent': reminderSent,
      'clinicId': clinicId,
    };
  }
}
