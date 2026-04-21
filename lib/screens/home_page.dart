import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_medication_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key, String firstName = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNavBar(selectedIndex: 0),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: db.collection('users').doc(uid).snapshots(),
          builder: (context, profileSnap) {
            final profileData = profileSnap.data?.data() as Map<String, dynamic>?;
            final firstName = ((profileData?['fullName'] as String?) ?? '').split(' ').first;

            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('users').doc(uid).collection('medications').snapshots(),
              builder: (context, medSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: db.collection('users').doc(uid).collection('doseLogs').snapshots(),
                  builder: (context, logSnap) {
                    final meds = medSnap.data?.docs ?? [];
                    final logs = logSnap.data?.docs ?? [];

                    final logStatuses = {
                      for (final log in logs)
                        log.id: (log.data() as Map<String, dynamic>)['status'] as String,
                    };

                    final slots = _buildTodaySlots(meds, logStatuses);
                    final upcomingByDay = _buildUpcomingSlots(meds);
                    final taken = slots.where((s) => s.status == 'Completed').length;
                    final progress = slots.isEmpty ? 0.0 : taken / slots.length;
                    final progressPct = '${(progress * 100).round()}%';

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Icon(Icons.favorite_border, size: 40, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hey $firstName,',
                              style: TextStyle(color: AppTheme.primaryColor, fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _greeting(),
                              style: TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              color: AppTheme.featureCardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.35), width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Today's Progress", style: TextStyle(fontSize: 16, color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        Text(
                                          progressPct,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 4,
                                            backgroundColor: AppTheme.featureCardColor,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                          ),
                                        ),
                                        Text(progressPct, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "Today's Schedule",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            if (slots.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text(
                                    'No medications scheduled for today.\nTap + to add one.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black45, fontSize: 15),
                                  ),
                                ),
                              )
                            else
                              ...slots.map((slot) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ScheduleCard(slot: slot, uid: uid, db: db),
                                  )),
                            const SizedBox(height: 32),
                            ...upcomingByDay.entries.map((entry) {
                              final dayLabel = _formatDayLabel(entry.key);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayLabel,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...entry.value.map((slot) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _ScheduleCard(slot: slot, uid: uid, db: db),
                                      )),
                                  const SizedBox(height: 20),
                                ],
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDayLabel(DateTime day) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (day == tomorrow) return 'Tomorrow';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[day.month - 1]} ${day.day}';
  }

  Map<DateTime, List<_MedSlot>> _buildUpcomingSlots(List<QueryDocumentSnapshot> meds) {
    final now = DateTime.now();
    final result = <DateTime, List<_MedSlot>>{};

    for (int dayOffset = 1; dayOffset <= 2; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);

      for (final med in meds) {
        final data = med.data() as Map<String, dynamic>;
        if (data['archived'] == true) continue;

        final startTs = data['startDate'] as Timestamp?;
        final endTs = data['endDate'] as Timestamp?;
        if (startTs == null || endTs == null) continue;

        final startDay = DateTime(startTs.toDate().year, startTs.toDate().month, startTs.toDate().day);
        final endDay = DateTime(endTs.toDate().year, endTs.toDate().month, endTs.toDate().day)
            .add(const Duration(days: 1));

        if (dayStart.isBefore(startDay) || dayStart.isAfter(endDay)) continue;

        final intakeTimes = List<String>.from(data['intakeTimes'] ?? []);
        for (final t in intakeTimes) {
          final parts = t.split(':');
          if (parts.length != 2) continue;
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final scheduledAt = DateTime(dayStart.year, dayStart.month, dayStart.day, hour, minute);

          final dateStr = '${dayStart.year}${dayStart.month.toString().padLeft(2, '0')}${dayStart.day.toString().padLeft(2, '0')}';
          final timeStr = '${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';
          final logId = '${med.id}_${dateStr}_$timeStr';

          result.putIfAbsent(dayStart, () => []);
          result[dayStart]!.add(_MedSlot(
            medId: med.id,
            logId: logId,
            name: data['name'] ?? '',
            dosage: '${data['dosage']} ${data['unit'] ?? ''}',
            count: '1 ${data['medType'] ?? ''}',
            scheduledAt: scheduledAt,
            status: 'Upcoming',
            medData: data,
          ));
        }
      }
      result[dayStart]?.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    return Map.fromEntries(
      result.entries.where((e) => e.value.isNotEmpty).toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<_MedSlot> _buildTodaySlots(
    List<QueryDocumentSnapshot> meds,
    Map<String, String> logStatuses,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final slots = <_MedSlot>[];

    for (final med in meds) {
      final data = med.data() as Map<String, dynamic>;
      if (data['archived'] == true) continue;

      final startTs = data['startDate'] as Timestamp?;
      final endTs = data['endDate'] as Timestamp?;
      if (startTs == null || endTs == null) continue;

      final startDay = DateTime(startTs.toDate().year, startTs.toDate().month, startTs.toDate().day);
      final endDay = DateTime(endTs.toDate().year, endTs.toDate().month, endTs.toDate().day)
          .add(const Duration(days: 1));

      if (todayStart.isBefore(startDay) || todayStart.isAfter(endDay)) continue;

      final intakeTimes = List<String>.from(data['intakeTimes'] ?? []);
      for (final t in intakeTimes) {
        final parts = t.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final scheduledAt = DateTime(now.year, now.month, now.day, hour, minute);

        final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final timeStr = '${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';
        final logId = '${med.id}_${dateStr}_$timeStr';

        final logStatus = logStatuses[logId];
        String status;
        if (logStatus == 'taken') {
          status = 'Completed';
        } else if (logStatus == 'missed') {
          status = 'Missed';
        } else if (now.isAfter(scheduledAt)) {
          status = 'Overdue';
        } else if (scheduledAt.difference(now).inMinutes <= 60) {
          status = 'Soon';
        } else {
          status = 'Upcoming';
        }

        slots.add(_MedSlot(
          medId: med.id,
          logId: logId,
          name: data['name'] ?? '',
          dosage: '${data['dosage']} ${data['unit'] ?? ''}',
          count: '1 ${data['medType'] ?? ''}',
          scheduledAt: scheduledAt,
          status: status,
          medData: data,
        ));
      }
    }

    slots.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return slots;
  }
}

class _MedSlot {
  final String medId;
  final String logId;
  final String name;
  final String dosage;
  final String count;
  final DateTime scheduledAt;
  final String status;
  final Map<String, dynamic> medData;

  const _MedSlot({
    required this.medId,
    required this.logId,
    required this.name,
    required this.dosage,
    required this.count,
    required this.scheduledAt,
    required this.status,
    required this.medData,
  });
}

class _ScheduleCard extends StatefulWidget {
  final _MedSlot slot;
  final String uid;
  final FirebaseFirestore db;

  const _ScheduleCard({required this.slot, required this.uid, required this.db});

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _uploading = false;
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.slot.status) {
      case 'Completed': return Colors.green;
      case 'Soon':      return Colors.amber;
      case 'Overdue':
      case 'Missed':    return Colors.redAccent;
      default:          return Colors.blueAccent;
    }
  }

  bool get _isTakeEnabled {
    final status = widget.slot.status;
    if (status == 'Completed' || status == 'Missed') return false;
    final diff = DateTime.now().difference(widget.slot.scheduledAt).inMinutes.abs();
    return diff <= 30;
  }

  Future<void> _markTaken(BuildContext context) async {
    final isEarly = widget.slot.status == 'Upcoming';

    if (isEarly) {
      final timeStr = TimeOfDay.fromDateTime(widget.slot.scheduledAt).format(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Take early?'),
          content: Text(
            'This dose is scheduled for $timeStr. '
            'Are you sure you want to log it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    String? proofUrl;
    if (!kIsWeb) {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );
      if (photo == null) return;

      if (mounted) setState(() => _uploading = true);
      try {
        final ref = FirebaseStorage.instance
            .ref('proofImages/${widget.uid}/${widget.slot.logId}.jpg');
        await ref.putData(
          await photo.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        proofUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) setState(() => _uploading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo upload failed: $e')),
          );
        }
        return;
      }
    }

    try {
      await widget.db
          .collection('users')
          .doc(widget.uid)
          .collection('doseLogs')
          .doc(widget.slot.logId)
          .set({
        'medId': widget.slot.medId,
        'scheduledAt': Timestamp.fromDate(widget.slot.scheduledAt),
        'status': 'taken',
        'takenAt': FieldValue.serverTimestamp(),
        'proofPath': proofUrl,
        if (isEarly) 'earlyTake': true,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleMenuAction(String value, BuildContext context) async {
    if (value == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddMedicationPage(
            editMedId: widget.slot.medId,
            editMedData: widget.slot.medData,
          ),
        ),
      );
    } else if (value == 'stop') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Stop Taking?'),
          content: Text(
            'Stop taking ${widget.slot.name}? It will be removed from your schedule.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop Taking', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        await widget.db
            .collection('users')
            .doc(widget.uid)
            .collection('medications')
            .doc(widget.slot.medId)
            .update({'archived': true});
        await NotificationService.cancelMedication(widget.slot.medId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.slot.name} has been stopped.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTake = widget.slot.status == 'Upcoming' ||
        widget.slot.status == 'Soon' ||
        widget.slot.status == 'Overdue';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        border: Border.all(color: _statusColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.slot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.slot.status,
                      style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.black45),
                    onSelected: (v) => _handleMenuAction(v, context),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'stop', child: Text('Stop Taking')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                TimeOfDay.fromDateTime(widget.slot.scheduledAt).format(context),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Dosage  -  ', style: TextStyle(color: Colors.black54)),
              Text(widget.slot.dosage, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text(widget.slot.count, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (showTake)
                _uploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _isTakeEnabled
                        ? GestureDetector(
                            onTap: () => _markTaken(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Take',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Take',
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                          ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const _BottomNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.navBarDark, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBarItem(icon: Icons.home, label: selectedIndex == 0 ? 'Home' : '', selected: selectedIndex == 0, onTap: () {}),
          _NavBarItem(icon: Icons.calendar_today, label: selectedIndex == 1 ? 'History' : '', selected: selectedIndex == 1, onTap: () => Navigator.of(context).pushReplacementNamed('/history')),
          _NavBarItem(icon: Icons.add, label: selectedIndex == 2 ? 'Add' : '', selected: selectedIndex == 2, onTap: () => Navigator.of(context).pushReplacementNamed('/add')),
          _NavBarItem(icon: Icons.menu, label: selectedIndex == 3 ? 'More' : '', selected: selectedIndex == 3, onTap: () => Navigator.of(context).pushReplacementNamed('/more')),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? AppTheme.primaryColor : Colors.white, size: 28),
          if (label.isNotEmpty)
            Text(label, style: TextStyle(color: selected ? AppTheme.primaryColor : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
