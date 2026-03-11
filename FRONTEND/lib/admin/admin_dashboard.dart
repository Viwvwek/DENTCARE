import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/theme.dart';
import '../models/scan_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final clinicId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsRow(clinicId),
                  const SizedBox(height: 24),
                  _buildSectionLabel('SCAN ACTIVITY'),
                  const SizedBox(height: 12),
                  _buildScanActivityChart(clinicId),
                  const SizedBox(height: 24),
                  _buildSectionLabel('SHADE DISTRIBUTION'),
                  const SizedBox(height: 12),
                  _buildShadeDistributionChart(clinicId),
                  const SizedBox(height: 24),
                  _buildSectionLabel('LIVE SCAN FEED'),
                  const SizedBox(height: 12),
                  _buildLiveScanFeed(clinicId),
                  const SizedBox(height: 24),
                  _buildSectionLabel('SYSTEM HEALTH'),
                  const SizedBox(height: 12),
                  _buildSystemHealth(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('QUICK ACTIONS'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: false,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.premiumGradient),
          padding: const EdgeInsets.fromLTRB(24, 55, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                    ),
                    child: const Text('ADMIN', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AppTheme.secondaryText,
      ),
    );
  }

  Widget _buildStatsRow(String clinicId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('scans')
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 30))))
          .snapshots(),
      builder: (context, scanSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('patients')
              .where('isArchived', isEqualTo: false)
              .snapshots(),
          builder: (context, patientSnap) {
            final totalScans = scanSnap.data?.docs.length ?? 0;
            final totalPatients = patientSnap.data?.docs.length ?? 0;

            // Calculate today's scans
            final today = DateTime.now();
            final todayScans = scanSnap.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              final ts = (data['timestamp'] as Timestamp).toDate();
              return ts.day == today.day && ts.month == today.month && ts.year == today.year;
            }).length ?? 0;

            // Avg confidence
            double avgConf = 0;
            if (scanSnap.data != null && scanSnap.data!.docs.isNotEmpty) {
              double sum = 0;
              for (final d in scanSnap.data!.docs) {
                final data = d.data() as Map<String, dynamic>;
                sum += (data['confidence'] as num?)?.toDouble() ?? 0.0;
              }
              avgConf = sum / scanSnap.data!.docs.length;
            }

            return Row(
              children: [
                _buildKpiCard('Today\'s Scans', '$todayScans', Icons.document_scanner_rounded, AppTheme.accent, '+${todayScans}'),
                const SizedBox(width: 12),
                _buildKpiCard('Monthly Scans', '$totalScans', Icons.analytics_rounded, const Color(0xFF6366F1), '30 days'),
                const SizedBox(width: 12),
                _buildKpiCard('Patients', '$totalPatients', Icons.people_rounded, const Color(0xFFF59E0B), 'Active'),
                const SizedBox(width: 12),
                _buildKpiCard('Avg. Confidence', '${(avgConf * 100).toStringAsFixed(0)}%', Icons.verified_rounded, const Color(0xFF10B981), 'AI Score'),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanActivityChart(String clinicId) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .collection('scans')
            .where('timestamp',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 7))))
            .snapshots(),
        builder: (context, snapshot) {
          // Build 7 days data
          final Map<int, int> scansPerDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] != null) {
                final ts = (data['timestamp'] as Timestamp).toDate();
                final daysAgo = DateTime.now().difference(ts).inDays;
                if (daysAgo >= 0 && daysAgo < 7) {
                  scansPerDay[6 - daysAgo] = (scansPerDay[6 - daysAgo] ?? 0) + 1;
                }
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scans Last 7 Days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (scansPerDay.values.isEmpty ? 5 : (scansPerDay.values.reduce((a, b) => a > b ? a : b) + 2)).toDouble(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          '${rod.toY.toInt()} scans',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('E').format(day),
                                style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText, fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: scansPerDay.entries.map((e) {
                      final isToday = e.key == 6;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            color: isToday ? AppTheme.accent : AppTheme.primary.withValues(alpha: 0.3),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShadeDistributionChart(String clinicId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .collection('scans')
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final Map<String, int> shadeCounts = {};
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final shade = data['shade'] as String? ?? 'Unknown';
              shadeCounts[shade] = (shadeCounts[shade] ?? 0) + 1;
            }
          }

          if (shadeCounts.isEmpty) {
            return const SizedBox(
              height: 80,
              child: Center(child: Text('No scan data yet', style: TextStyle(color: AppTheme.secondaryText))),
            );
          }

          final total = shadeCounts.values.fold<int>(0, (a, b) => a + b);
          final topShades = (shadeCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(6)
              .toList();

          final colors = [
            AppTheme.accent,
            AppTheme.primary,
            const Color(0xFF6366F1),
            const Color(0xFFF59E0B),
            const Color(0xFF10B981),
            const Color(0xFFEF4444),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Shade Results', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: PieChart(
                      PieChartData(
                        sections: topShades.asMap().entries.map((entry) {
                          final i = entry.key;
                          final shade = entry.value;
                          final pct = shade.value / total * 100;
                          return PieChartSectionData(
                            value: shade.value.toDouble(),
                            title: '${pct.toStringAsFixed(0)}%',
                            color: colors[i % colors.length],
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          );
                        }).toList(),
                        centerSpaceRadius: 20,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: topShades.asMap().entries.map((entry) {
                        final i = entry.key;
                        final shade = entry.value;
                        final pct = (shade.value / total * 100).toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text('Shade ${shade.key}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
                              const Spacer(),
                              Text('$pct%', style: TextStyle(fontSize: 11, color: colors[i % colors.length], fontWeight: FontWeight.w800)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLiveScanFeed(String clinicId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSkeletonFeed();
        }

        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
            child: const Center(child: Text('No recent scans', style: TextStyle(color: AppTheme.secondaryText))),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final shade = data['shade'] as String? ?? '??';
            final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
            final patientName = data['patientName'] as String? ?? 'Unknown';
            final doctorName = data['doctorName'] as String? ?? 'Unknown';
            final ts = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
            final isLow = (data['isLowConfidence'] as bool?) ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadow,
                border: isLow ? Border.all(color: Colors.orange.shade200) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(shade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
                            if (isLow) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('LOW CONF', style: TextStyle(color: Colors.orange.shade700, fontSize: 8, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        Text('Dr. $doctorName', style: AppTheme.subHeading.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(confidence * 100).toStringAsFixed(0)}%', style: TextStyle(color: confidence >= 0.75 ? AppTheme.accent : Colors.orange, fontWeight: FontWeight.w900, fontSize: 14)),
                      Text(DateFormat('HH:mm').format(ts), style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSkeletonFeed() {
    return Column(
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 78,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppTheme.softShadow),
      )),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Invite Staff', 'icon': Icons.person_add_rounded, 'color': AppTheme.accent},
      {'label': 'Add Patient', 'icon': Icons.person_rounded, 'color': AppTheme.primary},
      {'label': 'Audit Log', 'icon': Icons.shield_rounded, 'color': const Color(0xFF6366F1)},
      {'label': 'Analytics', 'icon': Icons.bar_chart_rounded, 'color': const Color(0xFFF59E0B)},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: actions.map((action) {
        final color = action['color'] as Color;
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${action['label']} — coming soon'), backgroundColor: color),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData, color: color, size: 20),
                const SizedBox(width: 8),
                Text(action['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemHealth() {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse('${dotenv.env['API_URL'] ?? "http://10.0.2.2:8000"}/health')).timeout(const Duration(seconds: 3)),
      builder: (context, snapshot) {
        bool isOnline = false;
        String uptime = 'Unknown';
        double latency = 0;

        if (snapshot.hasData && snapshot.data!.statusCode == 200) {
          isOnline = true;
          try {
            final data = jsonDecode(snapshot.data!.body);
            int sec = data['uptime_seconds'] ?? 0;
            if (sec > 3600) uptime = '${(sec / 3600).toStringAsFixed(1)} h';
            else if (sec > 60) uptime = '${(sec / 60).toStringAsFixed(0)} m';
            else uptime = '$sec s';
          } catch (_) {}
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.softShadow),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.storage_rounded, color: isOnline ? Colors.green : Colors.red, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("FastAPI AI Backend", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(isOnline ? "Online (Uptime: $uptime)" : "Offline", style: TextStyle(color: isOnline ? Colors.green : Colors.redAccent, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.red, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildHealthMetric(Icons.cloud_done_rounded, "Cloud DB", "Connected", AppTheme.accent)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildHealthMetric(Icons.memory_rounded, "Inference Node", isOnline ? "Active" : "Down", isOnline ? AppTheme.accent : Colors.redAccent)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthMetric(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
