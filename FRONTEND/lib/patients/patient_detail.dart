import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../models/scan_model.dart';
import '../reports/pdf_generator.dart';
import '../utils/theme.dart';
import 'patient_list.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';

class PatientDetailScreen extends StatelessWidget {
  final PatientModel patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroHeader(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (patient.hasMedicalFlags) _buildMedicalFlagsBanner(),
                _buildInfoGrid(),
                _buildSectionTitle('Shade Progression'),
                _buildScanHistory(),
                _buildSectionTitle('Contact & Insurance'),
                _buildContactInfo(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildEditButton(context),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.premiumGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accent, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      patient.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${patient.age} yrs · ${patient.gender} · ${patient.totalVisits} visits',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalFlagsBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'MEDICAL FLAGS',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (patient.allergies != null && patient.allergies!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Allergies: ${patient.allergies}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
          if (patient.medicalHistory != null && patient.medicalHistory!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'History: ${patient.medicalHistory}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    final items = [
      {'label': 'Phone', 'value': patient.phone, 'icon': Icons.phone_rounded},
      {'label': 'Email', 'value': patient.email ?? 'Not provided', 'icon': Icons.email_rounded},
      {'label': 'DOB', 'value': DateFormat('MMM dd, yyyy').format(patient.dateOfBirth), 'icon': Icons.cake_rounded},
      {'label': 'Last Visit', 'value': patient.lastVisitDate != null ? DateFormat('MMM dd, yyyy').format(patient.lastVisitDate!) : 'Never', 'icon': Icons.calendar_today},
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: AppTheme.accent, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['label'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText, fontWeight: FontWeight.w600)),
                    Text(item['value'] as String, style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
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

  Widget _buildScanHistory() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.scansBox).listenable(),
      builder: (context, Box box, _) {
        final allScans = box.values
            .map((e) => Map<String, dynamic>.from(e))
            .where((data) => data['patientId'] == patient.patientId)
            .toList();

        // Sort by timestamp
        allScans.sort((a, b) => 
            DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

        if (allScans.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Center(
                child: Text(
                  'No scans recorded yet',
                  style: AppTheme.subHeading.copyWith(fontSize: 14),
                ),
              ),
            ),
          );
        }

        final scans = allScans.map((data) => ScanModel.fromMap(data)).toList();

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              return _buildScanChip(context, scan, index == 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.accentShadow,
        ),
        child: IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientFormScreen(patient: patient),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanChip(BuildContext context, ScanModel scan, bool isLatest) {
    return GestureDetector(
      onTap: () {
        DentShadePdfGenerator.previewPdf(
          context: context,
          scan: scan,
          patient: patient,
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLatest ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLatest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('LATEST', style: TextStyle(color: AppTheme.accent, fontSize: 8, fontWeight: FontWeight.w900)),
            ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 20),
            Text(
              scan.shade,
              style: TextStyle(
                color: isLatest ? Colors.white : AppTheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              scan.confidencePercent,
              style: TextStyle(
                color: isLatest ? Colors.white70 : AppTheme.secondaryText,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('MMM dd').format(scan.timestamp),
              style: TextStyle(
                color: isLatest ? Colors.white60 : AppTheme.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          if (patient.address != null) _buildInfoRow('Address', patient.address!, Icons.home_outlined),
          if (patient.insuranceProvider != null) ...[
            _buildInfoRow('Insurance', patient.insuranceProvider!, Icons.shield_outlined),
            if (patient.insurancePolicyNumber != null)
              _buildInfoRow('Policy #', patient.insurancePolicyNumber!, Icons.numbers_rounded),
          ],
          if (patient.medications != null && patient.medications!.isNotEmpty)
            _buildInfoRow('Medications', patient.medications!, Icons.medication_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
              Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
