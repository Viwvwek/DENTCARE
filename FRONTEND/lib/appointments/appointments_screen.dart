import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/patient_model.dart';
import '../utils/theme.dart';
import '../utils/loading_overlay.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../widgets/bouncing_button.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildCalendarStrip()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
               TabBar(
                controller: _tabController,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.secondaryText,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'SCHEDULE'),
                  Tab(text: 'WAITING ROOM'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: _buildAddButton(context),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 120,
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
              const Text('APPOINTMENTS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text('${DateFormat('EEEE, MMMM d').format(_selectedDay)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildScheduleView(),
        _buildWaitingRoomView(),
      ],
    );
  }

  Widget _buildScheduleView() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.appointmentsBox).listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) {
          return _buildEmptyDay();
        }

        final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final appointments = box.values
            .map((e) => Map<String, dynamic>.from(e))
            .where((data) {
          final dt = _parseDate(data['dateTime']);
          return dt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                 dt.isBefore(endOfDay);
        }).toList();

        // Sort by time
        appointments.sort((a, b) => 
            _parseDate(a['dateTime']).compareTo(_parseDate(b['dateTime'])));

        if (appointments.isEmpty) {
          return _buildEmptyDay();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          physics: const BouncingScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final data = appointments[index];
            return _buildAppointmentCard(data['appointmentId'], data);
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _syncAppointments();
  }

  Future<void> _syncAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .collection('appointments')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        await DatabaseService.saveLocal(DatabaseService.appointmentsBox, doc.id, data);
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Widget _buildAppointmentCard(String id, Map<String, dynamic> data) {
    final dateTime = _parseDate(data['dateTime']);
    final status = data['status'] as String? ?? 'scheduled';
    final type = data['type'] as String? ?? 'Consultation';
    final patientName = data['patientName'] as String? ?? 'Unknown';
    final doctorName = data['doctorName'] as String? ?? '';

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Time column
            SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('HH:mm').format(dateTime),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary),
                  ),
                  Text(
                    DateFormat('a').format(dateTime),
                    style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // vertical divider
            Container(width: 1, color: AppTheme.background, margin: const EdgeInsets.symmetric(vertical: 16)),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
                        const Spacer(),
                        _buildStatusChip(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Dr. $doctorName · $type', style: AppTheme.subHeading.copyWith(fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip(type),
                        const Spacer(),
                        _buildActionButtons(id, status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 11, color: color),
          const SizedBox(width: 4),
          Text(type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String status) {
    return Row(
      children: [
        if (status == 'scheduled' || status == 'confirmed') ...[
          _actionBtn(Icons.check_circle_outline_rounded, AppTheme.accent, () => _updateStatus(id, 'in-progress')),
          const SizedBox(width: 6),
          _actionBtn(Icons.cancel_outlined, Colors.orangeAccent, () => _updateStatus(id, 'cancelled')),
          const SizedBox(width: 6),
        ],
        _actionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteAppointment(id)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return BouncingButton(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _deleteAppointment(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Delete locally
    final box = Hive.box(DatabaseService.appointmentsBox);
    await box.delete(id);
    
    // Delete from Firestore
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .collection('appointments')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint("Error deleting appointment remotely: $e");
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('clinics')
        .doc(user?.uid ?? '')
        .collection('appointments')
        .doc(id)
        .update({'status': newStatus});
  }

  Widget _buildWaitingRoomView() {
    return ValueListenableBuilder(
      valueListenable: Hive.box(DatabaseService.appointmentsBox).listenable(),
      builder: (context, Box box, _) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final appointments = box.values
            .map((e) => Map<String, dynamic>.from(e))
            .where((data) {
          final dt = _parseDate(data['dateTime']);
          final status = data['status'] as String? ?? 'scheduled';
          return dt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                 dt.isBefore(endOfDay) &&
                 ['scheduled', 'confirmed', 'in-progress'].contains(status);
        }).toList();

        // Sort by time
        appointments.sort((a, b) => 
            _parseDate(a['dateTime']).compareTo(_parseDate(b['dateTime'])));

        if (appointments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(Icons.event_available_rounded, size: 60, color: AppTheme.accent),
                const SizedBox(height: 16),
                const Text('Waiting Room Clear!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
                Text('No patients currently waiting today', style: AppTheme.subHeading.copyWith(fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          physics: const BouncingScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final data = appointments[index];
            final dateTime = _parseDate(data['dateTime']);
            final patientName = data['patientName'] as String? ?? 'Unknown';
            final status = data['status'] as String? ?? 'scheduled';
            final type = data['type'] as String? ?? '';

            return _WaitingRoomCard(
              index: index,
              patientName: patientName,
              type: type,
              dateTime: dateTime,
              status: status,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text('No sessions scheduled for this day.\nTap + to book an appointment.',
                textAlign: TextAlign.center,
                style: AppTheme.subHeading.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.accentShadow,
      ),
      child: IconButton(
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => _showBookingSheet(context),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookAppointmentSheet(selectedDate: _selectedDay),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in-progress': return AppTheme.accent;
      case 'confirmed': return const Color(0xFF6366F1);
      case 'completed': return const Color(0xFF10B981);
      case 'cancelled': return Colors.redAccent;
      case 'no-show': return Colors.orange;
      default: return AppTheme.primary;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'scan': return AppTheme.accent;
      case 'emergency': return Colors.redAccent;
      case 'follow-up': return const Color(0xFF6366F1);
      default: return AppTheme.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'scan': return Icons.document_scanner_rounded;
      case 'emergency': return Icons.emergency_rounded;
      case 'follow-up': return Icons.replay_rounded;
      default: return Icons.medical_services_rounded;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ─── Book Appointment Bottom Sheet ────────────────────────────────────────────
class _BookAppointmentSheet extends StatefulWidget {
  final DateTime selectedDate;
  const _BookAppointmentSheet({required this.selectedDate});

  @override
  State<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<_BookAppointmentSheet> {
  final _patientNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _patientId = '';
  String _type = 'Consultation';
  TimeOfDay _time = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Handle
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BOOK APPOINTMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary, fontSize: 14)),
                        Text(DateFormat('EEEE, MMMM d').format(widget.selectedDate), style: AppTheme.subHeading.copyWith(fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.secondaryText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _patientSearchField(),
                      const SizedBox(height: 14),
                      _timePicker(context),
                      const SizedBox(height: 14),
                      _typePicker(),
                      const SizedBox(height: 14),
                      _field(_notesCtrl, 'Notes (optional)', Icons.notes_rounded, maxLines: 3),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.premiumGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextButton(
                            onPressed: _isSaving ? null : _save,
                            child: Text(
                              _isSaving ? 'BOOKING...' : 'CONFIRM APPOINTMENT',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving) const PremiumLoadingOverlay(message: 'Booking', subMessage: 'Scheduling appointment'),
        ],
      ),
    );
  }

  Widget _patientSearchField() {
    return Autocomplete<Map<String, dynamic>>(
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
        _patientNameCtrl.text = selection['name'] as String? ?? '';
        _patientId = selection['patientId'] as String? ?? '';
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Search Patient',
            prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.accent, size: 20),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
          ),
          onChanged: (val) {
            _patientNameCtrl.text = val;
            _patientId = ''; // Reset ID if manually typed
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
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
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
      ),
    );
  }

  Widget _timePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _time);
        if (picked != null) setState(() => _time = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 12),
            Text(
              _time.format(context),
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _typePicker() {
    final types = ['Consultation', 'Scan', 'Follow-up', 'Emergency'];
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final isSelected = _type == t;
        return GestureDetector(
          onTap: () => setState(() => _type = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              t,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    if (_patientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a patient name'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await UserService.getCurrentProfile();
        final clinicId = profile?.clinicId ?? user.uid;
        final apptId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final dateTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          _time.hour,
          _time.minute,
        );

        final apptData = {
          'appointmentId': apptId,
          'patientId': _patientId,
          'patientName': _patientNameCtrl.text.trim(),
          'doctorUid': user.uid,
          'doctorName': profile?.displayName ?? user.email?.split('@').first ?? 'Doctor',
          'dateTime': dateTime.toIso8601String(),
          'durationMinutes': 30,
          'type': _type,
          'status': 'scheduled',
          'notes': _notesCtrl.text.trim(),
          'reminderSent': false,
          'clinicId': clinicId,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await DatabaseService.saveLocal(DatabaseService.appointmentsBox, apptId, apptData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked!'), backgroundColor: AppTheme.accent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _WaitingRoomCard extends StatefulWidget {
  final int index;
  final String patientName;
  final String type;
  final DateTime dateTime;
  final String status;

  const _WaitingRoomCard({
    required this.index,
    required this.patientName,
    required this.type,
    required this.dateTime,
    required this.status,
  });

  @override
  State<_WaitingRoomCard> createState() => _WaitingRoomCardState();
}

class _WaitingRoomCardState extends State<_WaitingRoomCard> {
  late Timer _timer;
  String _waitText = '';

  @override
  void initState() {
    super.initState();
    _updateWaitTime();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _updateWaitTime();
    });
  }

  void _updateWaitTime() {
    if (widget.status == 'in-progress') {
      setState(() => _waitText = 'IN PROGRESS');
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(widget.dateTime).inMinutes;

    setState(() {
      if (diff > 0) {
        _waitText = 'Waiting $diff min';
      } else if (diff == 0) {
        _waitText = 'Now';
      } else {
        _waitText = 'In ${-diff} min';
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.status == 'in-progress' ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.status == 'in-progress'
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: widget.status == 'in-progress' ? AppTheme.accent : AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: widget.status == 'in-progress' ? Colors.white : AppTheme.primary,
                  ),
                ),
                Text(
                  '${widget.type} · ${DateFormat('HH:mm').format(widget.dateTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.status == 'in-progress' ? Colors.white60 : AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _waitText,
                style: TextStyle(
                  color: widget.status == 'in-progress' ? AppTheme.accent : AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
