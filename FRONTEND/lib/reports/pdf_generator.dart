import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/scan_model.dart';
import '../models/patient_model.dart';

class DentShadePdfGenerator {
  static Future<Uint8List> generateScanReport({
    required ScanModel scan,
    required PatientModel patient,
    String clinicName = 'DentCare Premium Clinic',
    String clinicAddress = '123 Medical District, Healthcare City',
    String clinicPhone = '+1 (555) 000-0000',
    String doctorLicense = 'License #: DC-2024-001',
  }) async {
    final pdf = pw.Document(
      title: 'DentShade Scan Report',
      author: scan.doctorName,
      creator: 'DentShade AI Platform',
    );

    // Find VITA shade data
    final vitaShade = vitaShadeGuide.firstWhere(
      (s) => s.shade == scan.shade,
      orElse: () => vitaShadeGuide.first,
    );
    final shadeColor = PdfColor.fromRYB(
      vitaShade.r / 255,
      vitaShade.g / 255,
      vitaShade.b / 255,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          _buildHeader(clinicName, clinicAddress, clinicPhone),
          pw.SizedBox(height: 28),
          _buildReportTitle(scan),
          pw.SizedBox(height: 20),
          _buildPatientSection(patient),
          pw.SizedBox(height: 20),
          _buildResultSection(scan, shadeColor, vitaShade),
          pw.SizedBox(height: 20),
          if (scan.clinicalNotes != null && scan.clinicalNotes!.isNotEmpty)
            _buildNotesSection(scan),
          if (scan.treatmentRecommendation != null && scan.treatmentRecommendation!.isNotEmpty)
            _buildRecommendationsSection(scan),
          pw.SizedBox(height: 20),
          _buildVitaScale(scan.shade),
          pw.Spacer(),
          _buildFooter(scan, doctorLicense),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String clinicName, String address, String phone) {
    return pw.Container(
      color: const PdfColor.fromInt(0xFF0F2744),
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DENTSHADE',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF2DD4BF),
                  letterSpacing: 3,
                ),
              ),
              pw.Text(
                'AI DENTAL SHADE ANALYSIS',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: const PdfColor(1, 1, 1, 0.6),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                clinicName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(address, style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.6))),
              pw.Text(phone, style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportTitle(ScanModel scan) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SCAN ANALYSIS REPORT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0F2744),
              letterSpacing: 1.5,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Report ID: ${scan.scanId.substring(0, 8).toUpperCase()}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                DateFormat('MMMM dd, yyyy • HH:mm').format(scan.timestamp),
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientSection(PatientModel patient) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF0FDFA),
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Text(
                'PATIENT INFORMATION',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF2DD4BF),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Row(
                children: [
                  pw.Expanded(child: _infoRow('Full Name', patient.name)),
                  pw.Expanded(child: _infoRow('Date of Birth', DateFormat('MMM dd, yyyy').format(patient.dateOfBirth))),
                  pw.Expanded(child: _infoRow('Age / Gender', '${patient.age} yrs / ${patient.gender}')),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: pw.Row(
                children: [
                  pw.Expanded(child: _infoRow('Phone', patient.phone)),
                  pw.Expanded(child: _infoRow('Email', patient.email ?? 'N/A')),
                  pw.Expanded(child: _infoRow('Insurance', patient.insuranceProvider ?? 'N/A')),
                ],
              ),
            ),
            if (patient.hasMedicalFlags) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const PdfColor.fromInt(0xFFFFF5F5),
                child: pw.Text(
                  '⚠  MEDICAL FLAGS: ${[
                    if (patient.allergies != null && patient.allergies!.isNotEmpty) 'Allergies: ${patient.allergies}',
                    if (patient.medicalHistory != null && patient.medicalHistory!.isNotEmpty) 'History: ${patient.medicalHistory}',
                  ].join(' | ')}',
                  style: pw.TextStyle(fontSize: 9, color: const PdfColor.fromInt(0xFFDC2626)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildResultSection(ScanModel scan, PdfColor shadeColor, VitaShade vitaShade) {
    final confidencePercent = (scan.confidence * 100).toStringAsFixed(1);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Main Result Box
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF0F2744),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PREDICTED SHADE', style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.6), letterSpacing: 1.5)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Color Swatch
                      pw.Container(
                        width: 50, height: 50,
                        decoration: pw.BoxDecoration(
                          color: shadeColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          border: pw.Border.all(color: PdfColors.white, width: 2),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            scan.shade,
                            style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2DD4BF)),
                          ),
                          pw.Text('Group ${vitaShade.group} · VITA Classical', style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.6))),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(vitaShade.description, style: pw.TextStyle(fontSize: 10, color: const PdfColor(1, 1, 1, 0.7))),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          // Confidence Box
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONFIDENCE', style: pw.TextStyle(fontSize: 8, letterSpacing: 1.5, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '$confidencePercent%',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: scan.confidence >= 0.75
                              ? const PdfColor.fromInt(0xFF2DD4BF)
                              : const PdfColor.fromInt(0xFFEF4444),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      // Progress bar
                      pw.Container(
                        height: 6,
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        scan.confidence >= 0.9 ? 'High Confidence' : scan.confidence >= 0.75 ? 'Good' : 'Low — Retake Suggested',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SCAN TYPE', style: pw.TextStyle(fontSize: 8, letterSpacing: 1.5, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(scan.scanType ?? 'Shade Match', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F2744))),
                      if (scan.toothNumber != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Tooth #${scan.toothNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ],
                      pw.SizedBox(height: 8),
                      pw.Text('Performed by', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                      pw.Text(scan.doctorName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F2744))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(ScanModel scan) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 20),
      child: pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        padding: const pw.EdgeInsets.all(16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CLINICAL NOTES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5, color: const PdfColor.fromInt(0xFF0F2744))),
            pw.SizedBox(height: 8),
            pw.Text(scan.clinicalNotes!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, lineSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildRecommendationsSection(ScanModel scan) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: pw.Container(
        width: double.infinity,
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF0FDFA),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        padding: const pw.EdgeInsets.all(16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('AI TREATMENT RECOMMENDATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5, color: const PdfColor.fromInt(0xFF2DD4BF))),
            pw.SizedBox(height: 8),
            pw.Text(scan.treatmentRecommendation!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, lineSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildVitaScale(String predictedShade) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('VITA CLASSICAL SHADE SCALE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5, color: PdfColors.grey600)),
          pw.SizedBox(height: 10),
          ...['A', 'B', 'C', 'D'].map((group) {
            final groupShades = vitaShadeGuide.where((s) => s.group == group).toList();
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 16,
                    child: pw.Text(group, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                  ),
                  pw.SizedBox(width: 6),
                  ...groupShades.map((shade) {
                    final isPredicted = shade.shade == predictedShade;
                    return pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                        child: pw.Container(
                          height: isPredicted ? 28 : 20,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromRYB(shade.r / 255, shade.g / 255, shade.b / 255),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: isPredicted ? pw.Border.all(color: const PdfColor.fromInt(0xFF0F2744), width: 1.5) : null,
                          ),
                          child: isPredicted
                              ? pw.Center(child: pw.Text(shade.shade, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F2744))))
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(ScanModel scan, String license) {
    return pw.Container(
      color: const PdfColor.fromInt(0xFFF8FAFC),
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 18),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Dr. ${scan.doctorName}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F2744)),
              ),
              pw.Text(license, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.SizedBox(height: 12),
              pw.Container(
                width: 140,
                height: 1,
                color: PdfColors.grey400,
              ),
              pw.SizedBox(height: 4),
              pw.Text('Digital Signature', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated by DentShade AI Platform', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
              pw.Text('Report ID: ${scan.scanId.substring(0, 12).toUpperCase()}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
              pw.Text(
                'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F2744))),
      ],
    );
  }

  // ─── Save & Share ────────────────────────────────────────────────────────────
  static Future<void> sharePdfReport({
    required ScanModel scan,
    required PatientModel patient,
  }) async {
    final bytes = await generateScanReport(scan: scan, patient: patient);
    final dir = await getTemporaryDirectory();
    final fileName = 'DentShade_${patient.name.replaceAll(' ', '_')}_${scan.shade}_${DateFormat('yyyyMMdd').format(scan.timestamp)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'DentShade Scan Report — ${patient.name}');
  }

  static Future<void> previewPdf({
    required BuildContext context,
    required ScanModel scan,
    required PatientModel patient,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => generateScanReport(scan: scan, patient: patient),
      name: 'DentShade_Report_${scan.shade}',
    );
  }
}
