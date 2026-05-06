import 'package:cloud_firestore/cloud_firestore.dart';

class ScanModel {
  final String scanId;
  final String patientId;
  final String patientName;
  final String doctorUid;
  final String doctorName;
  final String clinicId;
  final String shade;
  final double confidence;
  final String imageUrl;
  final double? qualityScore;
  final bool isLowConfidence;
  final String? clinicalNotes;
  final String? treatmentRecommendation;
  final String? toothNumber;
  final String? scanType;
  final DateTime timestamp;
  final String? appointmentId;
  final bool isFlaggedForReview;

  const ScanModel({
    required this.scanId,
    required this.patientId,
    required this.patientName,
    required this.doctorUid,
    required this.doctorName,
    required this.clinicId,
    required this.shade,
    required this.confidence,
    required this.imageUrl,
    this.qualityScore,
    required this.isLowConfidence,
    this.clinicalNotes,
    this.treatmentRecommendation,
    this.toothNumber,
    this.scanType,
    required this.timestamp,
    this.appointmentId,
    this.isFlaggedForReview = false,
  });

  String get confidenceLabel {
    if (confidence >= 0.9) return 'High';
    if (confidence >= 0.75) return 'Good';
    if (confidence >= 0.5) return 'Low';
    return 'Very Low';
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  factory ScanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    return ScanModel(
      scanId: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorUid: data['doctorUid'] ?? '',
      doctorName: data['doctorName'] ?? '',
      clinicId: data['clinicId'] ?? '',
      shade: data['shade'] ?? '',
      confidence: (data['confidence'] as num).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      qualityScore: data['qualityScore'] != null
          ? (data['qualityScore'] as num).toDouble()
          : null,
      isLowConfidence: data['isLowConfidence'] ?? false,
      clinicalNotes: data['clinicalNotes'],
      treatmentRecommendation: data['treatmentRecommendation'],
      toothNumber: data['toothNumber'],
      scanType: data['scanType'],
      timestamp: parseDate(data['timestamp']),
      appointmentId: data['appointmentId'],
      isFlaggedForReview: data['isFlaggedForReview'] ?? false,
    );
  }

  factory ScanModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    return ScanModel(
      scanId: data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorUid: data['doctorUid'] ?? '',
      doctorName: data['doctorName'] ?? '',
      clinicId: data['clinicId'] ?? '',
      shade: data['shade'] ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imagePath'] ?? '',
      qualityScore: data['qualityScore'] != null
          ? (data['qualityScore'] as num).toDouble()
          : null,
      isLowConfidence: data['isLowConfidence'] ?? false,
      clinicalNotes: data['clinicalNotes'],
      treatmentRecommendation: data['insight'],
      toothNumber: data['toothNumber'],
      scanType: data['scanType'],
      timestamp: parseDate(data['timestamp']),
      appointmentId: data['appointmentId'],
      isFlaggedForReview: data['isFlaggedForReview'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorUid': doctorUid,
      'doctorName': doctorName,
      'clinicId': clinicId,
      'shade': shade,
      'confidence': confidence,
      'imageUrl': imageUrl,
      if (qualityScore != null) 'qualityScore': qualityScore,
      'isLowConfidence': isLowConfidence,
      if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
      if (treatmentRecommendation != null)
        'treatmentRecommendation': treatmentRecommendation,
      if (toothNumber != null) 'toothNumber': toothNumber,
      if (scanType != null) 'scanType': scanType,
      'timestamp': Timestamp.fromDate(timestamp),
      if (appointmentId != null) 'appointmentId': appointmentId,
      'isFlaggedForReview': isFlaggedForReview,
    };
  }
}

// VITA Classical Shade Guide data
class VitaShade {
  final String shade;
  final int r, g, b;
  final String group;
  final String description;

  const VitaShade({
    required this.shade,
    required this.r,
    required this.g,
    required this.b,
    required this.group,
    required this.description,
  });
}

const List<VitaShade> vitaShadeGuide = [
  VitaShade(shade: 'B1', r: 252, g: 242, b: 220, group: 'B', description: 'Lightest shade — ideal for whitening targets'),
  VitaShade(shade: 'A1', r: 247, g: 234, b: 208, group: 'A', description: 'Very light shade — natural bright white'),
  VitaShade(shade: 'B2', r: 247, g: 230, b: 195, group: 'B', description: 'Light shade with warm undertone'),
  VitaShade(shade: 'D2', r: 242, g: 224, b: 192, group: 'D', description: 'Light reddish-grey shade'),
  VitaShade(shade: 'A2', r: 240, g: 220, b: 185, group: 'A', description: 'Most common natural shade — slightly warm'),
  VitaShade(shade: 'B3', r: 234, g: 212, b: 170, group: 'B', description: 'Medium-light with yellow undertones'),
  VitaShade(shade: 'A3', r: 228, g: 200, b: 155, group: 'A', description: 'Medium shade — common in adults'),
  VitaShade(shade: 'D3', r: 223, g: 198, b: 152, group: 'D', description: 'Medium grey-red'),
  VitaShade(shade: 'B4', r: 218, g: 192, b: 148, group: 'B', description: 'Medium shade with strong yellow tone'),
  VitaShade(shade: 'A3.5', r: 213, g: 187, b: 140, group: 'A', description: 'Medium-dark — common in older patients'),
  VitaShade(shade: 'C1', r: 210, g: 185, b: 142, group: 'C', description: 'Grey undertone — medium'),
  VitaShade(shade: 'C2', r: 204, g: 175, b: 130, group: 'C', description: 'Medium-grey shade'),
  VitaShade(shade: 'D4', r: 200, g: 170, b: 125, group: 'D', description: 'Dark reddish-grey'),
  VitaShade(shade: 'A4', r: 195, g: 165, b: 118, group: 'A', description: 'Dark amber/yellow shade'),
  VitaShade(shade: 'C3', r: 190, g: 158, b: 112, group: 'C', description: 'Dark grey shade'),
  VitaShade(shade: 'C4', r: 182, g: 148, b: 104, group: 'C', description: 'Darkest classical shade'),
];
