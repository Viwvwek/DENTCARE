import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/theme.dart';

class ScanReportsScreen extends StatelessWidget {
  const ScanReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('HISTORICAL LOGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: AppTheme.primary,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scans')
            .where('doctorEmail', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 80, color: Colors.black12),
                  const SizedBox(height: 16),
                  Text("No historical records found", style: AppTheme.subHeading),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildReportCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    final shade = data['shade'] ?? 'Unknown';
    final confidence = data['confidence'] ?? 0.0;
    final timestamp = data['timestamp'] as Timestamp?;

    String dateString = "Recents";
    if (timestamp != null) {
      final d = timestamp.toDate();
      dateString = "${d.day}/${d.month} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.analytics_outlined, color: AppTheme.accent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Shade Analysis: $shade", style: AppTheme.cardTitle),
                const SizedBox(height: 4),
                Text(dateString, style: AppTheme.subHeading.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${(confidence * 100).toStringAsFixed(1)}%",
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
