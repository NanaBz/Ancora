import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverClientsPage extends StatefulWidget {
  const CaregiverClientsPage({Key? key}) : super(key: key);

  @override
  State<CaregiverClientsPage> createState() => _CaregiverClientsPageState();
}

class _CaregiverClientsPageState extends State<CaregiverClientsPage> {
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final patientUid =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final db = FirebaseFirestore.instance;

    if (patientUid.isEmpty) {
      return _PatientListPage(db: db);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 1),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: db.collection('users').doc(patientUid).get(),
          builder: (context, profileSnap) {
            final profile =
                profileSnap.data?.data() as Map<String, dynamic>?;
            final name = (profile?['fullName'] as String?) ?? '…';
            final age = profile?['age'] as int?;

            return StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('users')
                  .doc(patientUid)
                  .collection('doseLogs')
                  .snapshots(),
              builder: (context, logsSnap) {
                final logs = logsSnap.data?.docs ?? [];
                final adherence = _monthAdherence(logs);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client Details',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Follow your client's history and adherence",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.favorite_border,
                                size: 28, color: AppTheme.primaryColor),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(Icons.person,
                                        size: 32, color: Colors.black38),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        if (age != null)
                                          Text('$age years old',
                                              style: const TextStyle(
                                                  color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(adherence * 100).round()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: adherence,
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    adherence >= 0.8
                                        ? AppTheme.primaryColor
                                        : Colors.redAccent),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                adherence >= 0.8
                                    ? 'Status : Perfect!'
                                    : 'Status : Needs Attention',
                                style: TextStyle(
                                    color: adherence >= 0.8
                                        ? AppTheme.primaryColor
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('History',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        _ClientCalendarWidget(
                          logs: logs,
                          viewMonth: _viewMonth,
                          onMonthChanged: (m) =>
                              setState(() => _viewMonth = m),
                        ),
                        const SizedBox(height: 32),
                        const Text('Dose Log',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        _ClientDoseLogList(logs: logs),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _monthAdherence(List<QueryDocumentSnapshot> logs) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    int taken = 0, total = 0;
    for (final log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final ts = data['scheduledAt'] as Timestamp?;
      if (ts == null) continue;
      final dt = ts.toDate();
      if (dt.isBefore(monthStart) || dt.isAfter(now)) continue;
      total++;
      if ((data['status'] as String?) == 'taken') taken++;
    }
    return total == 0 ? 1.0 : taken / total;
  }
}

class _PatientListPage extends StatelessWidget {
  final FirebaseFirestore db;
  const _PatientListPage({required this.db});

  @override
  Widget build(BuildContext context) {
    final caregiverUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 1),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: db.collection('users').doc(caregiverUid).collection('patients').snapshots(),
          builder: (context, snap) {
            final patients = snap.data?.docs ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clients', style: TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Select a patient', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w400)),
                        ],
                      ),
                      Icon(Icons.favorite_border, size: 32, color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (patients.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Text(
                          'No patients linked yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45, fontSize: 15),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final data = patients[i].data() as Map<String, dynamic>;
                          final name = (data['fullName'] as String?) ?? 'Patient';
                          final displayId = (data['displayId'] as String?) ?? '----';
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pushReplacementNamed(
                              '/caregiver-clients',
                              arguments: patients[i].id,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.person, color: AppTheme.primaryColor),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.black38),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ClientCalendarWidget extends StatelessWidget {
  final List<QueryDocumentSnapshot> logs;
  final DateTime viewMonth;
  final void Function(DateTime) onMonthChanged;

  const _ClientCalendarWidget({
    required this.logs,
    required this.viewMonth,
    required this.onMonthChanged,
  });

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final dayStatuses = _buildDayStatuses();
    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth =
        DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;

    final cells = <Widget>[
      for (int i = 0; i < startOffset; i++) const SizedBox(),
      for (int d = 1; d <= daysInMonth; d++)
        _DayCell(day: d, status: dayStatuses[d]),
    ];
    while (cells.length % 7 != 0) { cells.add(const SizedBox()); }

    final rows = <TableRow>[
      TableRow(
        children: [
          for (final d in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
            Center(
              child: Text(d,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    ];
    for (int w = 0; w < cells.length ~/ 7; w++) {
      rows.add(TableRow(children: List.generate(7, (d) => cells[w * 7 + d])));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(
                    DateTime(viewMonth.year, viewMonth.month - 1)),
              ),
              Text(
                '${_monthNames[viewMonth.month - 1]} ${viewMonth.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                    DateTime(viewMonth.year, viewMonth.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Table(children: rows),
        ],
      ),
    );
  }

  Map<int, String> _buildDayStatuses() {
    final counts = <int, Map<String, int>>{};
    for (final log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final ts = data['scheduledAt'] as Timestamp?;
      if (ts == null) continue;
      final dt = ts.toDate();
      if (dt.year != viewMonth.year || dt.month != viewMonth.month) continue;
      final status = data['status'] as String? ?? '';
      counts.putIfAbsent(dt.day, () => {'taken': 0, 'missed': 0});
      counts[dt.day]![status] = (counts[dt.day]![status] ?? 0) + 1;
    }
    final result = <int, String>{};
    for (final e in counts.entries) {
      if ((e.value['missed'] ?? 0) > 0) {
        result[e.key] = 'missed';
      } else if ((e.value['taken'] ?? 0) > 0) {
        result[e.key] = 'taken';
      }
    }
    return result;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String? status;
  const _DayCell({required this.day, this.status});

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color fg = Colors.black;
    if (status == 'taken') { bg = AppTheme.primaryColor; fg = Colors.white; }
    if (status == 'missed') { bg = Colors.redAccent; fg = Colors.white; }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: bg != null
              ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8))
              : null,
          child: Center(
            child: Text('$day',
                style:
                    TextStyle(color: fg, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _ClientDoseLogList extends StatelessWidget {
  final List<QueryDocumentSnapshot> logs;
  const _ClientDoseLogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) {
        final aTs = (a.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp?;
        final bTs = (b.data() as Map<String, dynamic>)['scheduledAt'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

    if (sorted.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('No dose logs yet.', style: TextStyle(color: Colors.black45)),
        ),
      );
    }

    return Column(
      children: sorted.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['scheduledAt'] as Timestamp?;
        final status = (data['status'] as String?) ?? '';
        final proofPath = data['proofPath'] as String?;
        final dt = ts?.toDate();
        final label = dt == null
            ? '—'
            : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(
                      status == 'taken' ? 'Taken' : 'Missed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'taken' ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              if (proofPath != null && proofPath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    proofPath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CaregiverBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const _CaregiverBottomNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navBarDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home,
            label: selectedIndex == 0 ? 'Home' : '',
            selected: selectedIndex == 0,
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('/caregiver-home'),
          ),
          _NavItem(
            icon: Icons.groups,
            label: selectedIndex == 1 ? 'Clients' : '',
            selected: selectedIndex == 1,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.person_add,
            label: selectedIndex == 2 ? 'Add User' : '',
            selected: selectedIndex == 2,
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('/caregiver-add-user'),
          ),
          _NavItem(
            icon: Icons.menu,
            label: selectedIndex == 3 ? 'More' : '',
            selected: selectedIndex == 3,
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('/caregiver-more'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: selected ? AppTheme.primaryColor : Colors.white,
              size: 28),
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
