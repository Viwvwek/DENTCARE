import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanReportsScreen extends StatelessWidget {
  const ScanReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4FD1C5),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scans')
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
              child: Text(
                'No historical scans found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final shade = data['shade'] ?? 'Unknown';
              final confidence = data['confidence'] ?? 0.0;
              final email = data['doctorEmail'] ?? 'Unknown Doctor';
              final timestamp = data['timestamp'] as Timestamp?;

              String dateString = "Unknown Date";
              if (timestamp != null) {
                final d = timestamp.toDate();
                dateString = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6FFFA),
                    child: Icon(Icons.document_scanner, color: Color(0xFF38B2AC)),
                  ),
                  title: Text(
                    'Shade: $shade',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('By: $email', style: const TextStyle(color: Colors.black87)),
                      Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}% | $dateString', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
