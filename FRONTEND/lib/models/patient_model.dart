import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String patientId;
  final String clinicId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String phone;
  final String? email;
  final String? address;
  final String? medicalHistory;
  final String? allergies;
  final String? medications;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String assignedDoctorUid;
  final String? referredBy;
  final int totalVisits;
  final DateTime? lastVisitDate;
  final DateTime createdAt;
  final bool isArchived;

  const PatientModel({
    required this.patientId,
    required this.clinicId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    this.email,
    this.address,
    this.medicalHistory,
    this.allergies,
    this.medications,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    required this.assignedDoctorUid,
    this.referredBy,
    this.totalVisits = 0,
    this.lastVisitDate,
    required this.createdAt,
    this.isArchived = false,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get hasMedicalFlags =>
      (allergies != null && allergies!.isNotEmpty) ||
      (medicalHistory != null && medicalHistory!.isNotEmpty);

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    return PatientModel(
      patientId: doc.id,
      clinicId: data['clinicId'] ?? '',
      name: data['name'] ?? '',
      dateOfBirth: parseDate(data['dateOfBirth'], fallback: DateTime(1990)),
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      medicalHistory: data['medicalHistory'],
      allergies: data['allergies'],
      medications: data['medications'],
      insuranceProvider: data['insuranceProvider'],
      insurancePolicyNumber: data['insurancePolicyNumber'],
      assignedDoctorUid: data['assignedDoctorUid'] ?? '',
      referredBy: data['referredBy'],
      totalVisits: data['totalVisits'] ?? 0,
      lastVisitDate: data['lastVisitDate'] != null
          ? parseDate(data['lastVisitDate'])
          : null,
      createdAt: parseDate(data['createdAt']),
      isArchived: data['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (medicalHistory != null) 'medicalHistory': medicalHistory,
      if (allergies != null) 'allergies': allergies,
      if (medications != null) 'medications': medications,
      if (insuranceProvider != null) 'insuranceProvider': insuranceProvider,
      if (insurancePolicyNumber != null)
        'insurancePolicyNumber': insurancePolicyNumber,
      'assignedDoctorUid': assignedDoctorUid,
      if (referredBy != null) 'referredBy': referredBy,
      'totalVisits': totalVisits,
      if (lastVisitDate != null)
        'lastVisitDate': Timestamp.fromDate(lastVisitDate!),
      'createdAt': Timestamp.fromDate(createdAt),
      'isArchived': isArchived,
    };
  }

  PatientModel copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? medicalHistory,
    String? allergies,
    String? medications,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? assignedDoctorUid,
    String? referredBy,
    int? totalVisits,
    DateTime? lastVisitDate,
    bool? isArchived,
  }) {
    return PatientModel(
      patientId: patientId,
      clinicId: clinicId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      assignedDoctorUid: assignedDoctorUid ?? this.assignedDoctorUid,
      referredBy: referredBy ?? this.referredBy,
      totalVisits: totalVisits ?? this.totalVisits,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
