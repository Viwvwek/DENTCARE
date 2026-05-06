import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/bouncing_button.dart';

class GlobalHistoryScreen extends StatelessWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          _buildScanHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.premiumGradient),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'SCAN HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Comprehensive record of all clinical scans',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistoryList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.scansBox).listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppTheme.secondaryText.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No scan history found', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        final scans = box.values.toList().reversed.toList();

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final scan = Map<String, dynamic>.from(scans[index]);
                return _buildScanCard(context, scan);
              },
              childCount: scans.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanCard(BuildContext context, Map<String, dynamic> scan) {
    final DateTime timestamp = DateTime.parse(scan['timestamp']);
    final String patientName = (scan['patientName'] != null && scan['patientName'].toString().isNotEmpty) 
        ? scan['patientName'] 
        : 'Unassigned';
    final String shade = scan['shade'] ?? '--';
    final double confidence = scan['confidence'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.analytics_rounded, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy · hh:mm a').format(timestamp),
                    style: AppTheme.subHeading.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shade,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.accent),
                ),
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}% conf.',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BouncingButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _editScan(context, scan);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 16),
                  ),
                ),
                const SizedBox(height: 6),
                BouncingButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _deleteScan(context, scan);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editScan(BuildContext context, Map<String, dynamic> scan) async {
    String currentName = scan['patientName'] == 'Unassigned' ? '' : scan['patientName'];
    String newPatientId = scan['patientId'] ?? '';
    String typedName = currentName;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Patient Name', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
        content: SizedBox(
          width: double.maxFinite,
          child: Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: currentName),
            displayStringForOption: (option) => option['name'] as String? ?? 'Unknown',
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              final patientsBox = Hive.box(DatabaseService.patientsBox);
              final patients = patientsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
              return patients.where((patient) {
                final name = (patient['name'] as String? ?? '').toLowerCase();
                return name.contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (Map<String, dynamic> selection) {
              typedName = selection['name'] as String? ?? '';
              newPatientId = selection['patientId'] as String? ?? '';
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              controller.addListener(() {
                typedName = controller.text;
                if (typedName != currentName) {
                  newPatientId = ''; // Reset ID if user types manually
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(hintText: 'Search or enter patient name'),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option['name'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          subtitle: Text(option['phone'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, typedName.trim()),
            child: const Text('Save', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName != null) {
      scan['patientName'] = newName.isEmpty ? 'Unassigned' : newName;
      scan['patientId'] = newPatientId;
      await DatabaseService.saveLocal(DatabaseService.scansBox, scan['id'], scan);
    }
  }

  Future<void> _deleteScan(BuildContext context, Map<String, dynamic> scan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
        content: const Text('Are you sure you want to delete this scan from history?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Hive.box(DatabaseService.scansBox).delete(scan['id']);
      // Remote deletion (if synced) requires cloud function or manual delete
      // Since scans are sometimes subcollections, we optimistically delete locally.
    }
  }
}
