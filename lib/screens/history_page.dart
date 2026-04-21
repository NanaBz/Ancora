import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNavBar(selectedIndex: 1),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('users')
              .doc(uid)
              .collection('doseLogs')
              .snapshots(),
          builder: (context, snap) {
            final logs = snap.data?.docs ?? [];
            final stats = _computeStats(logs);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '& Statistics',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.favorite_border,
                            size: 32, color: AppTheme.primaryColor),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.show_chart,
                            label: '7 Day Average',
                            value: '${stats.sevenDayAvg.round()}%',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.anchor,
                            label: 'Current Streak',
                            value: '${stats.streak} Days',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Records',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _CalendarWidget(
                      logs: logs,
                      viewMonth: _viewMonth,
                      onMonthChanged: (m) => setState(() => _viewMonth = m),
                    ),
                    const SizedBox(height: 32),
                    const Text('Dose Log',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _DoseLogList(logs: logs),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _HistoryStats _computeStats(List<QueryDocumentSnapshot> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayMap = <DateTime, Map<String, int>>{};
    for (final log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final ts = data['scheduledAt'] as Timestamp?;
      if (ts == null) continue;
      final dt = ts.toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      dayMap.putIfAbsent(day, () => {'taken': 0, 'missed': 0});
      final status = data['status'] as String? ?? '';
      dayMap[day]![status] = (dayMap[day]![status] ?? 0) + 1;
    }

    int taken7 = 0, total7 = 0;
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final counts = dayMap[day];
      if (counts != null) {
        taken7 += counts['taken'] ?? 0;
        total7 += (counts['taken'] ?? 0) + (counts['missed'] ?? 0);
      }
    }
    final avg = total7 == 0 ? 0.0 : taken7 / total7 * 100;

    int streak = 0;
    for (int i = 0; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      final counts = dayMap[day];
      if (counts == null || (counts['taken'] ?? 0) == 0) break;
      if ((counts['missed'] ?? 0) > 0) break;
      streak++;
    }

    return _HistoryStats(sevenDayAvg: avg, streak: streak);
  }
}

class _HistoryStats {
  final double sevenDayAvg;
  final int streak;
  const _HistoryStats({required this.sevenDayAvg, required this.streak});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final List<QueryDocumentSnapshot> logs;
  final DateTime viewMonth;
  final void Function(DateTime) onMonthChanged;

  const _CalendarWidget({
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
    // weekday: Mon=1..Sun=7 → offset so Sun=0
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
      rows.add(TableRow(
          children:
              List.generate(7, (d) => cells[w * 7 + d])));
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
      if (dt.year != viewMonth.year || dt.month != viewMonth.month) {
        continue;
      }
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
    if (status == 'taken') {
      bg = AppTheme.primaryColor;
      fg = Colors.white;
    } else if (status == 'missed') {
      bg = Colors.redAccent;
      fg = Colors.white;
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: bg != null
              ? BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8))
              : null,
          child: Center(
            child: Text('$day',
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _DoseLogList extends StatelessWidget {
  final List<QueryDocumentSnapshot> logs;
  const _DoseLogList({required this.logs});

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

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const _BottomNavBar({required this.selectedIndex});

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
          _NavBarItem(
            icon: Icons.home,
            label: selectedIndex == 0 ? 'Home' : '',
            selected: selectedIndex == 0,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/home'),
          ),
          _NavBarItem(
            icon: Icons.calendar_today,
            label: selectedIndex == 1 ? 'History' : '',
            selected: selectedIndex == 1,
            onTap: () {},
          ),
          _NavBarItem(
            icon: Icons.add,
            label: selectedIndex == 2 ? 'Add' : '',
            selected: selectedIndex == 2,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/add'),
          ),
          _NavBarItem(
            icon: Icons.menu,
            label: selectedIndex == 3 ? 'More' : '',
            selected: selectedIndex == 3,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/more'),
          ),
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

  const _NavBarItem({
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
                color:
                    selected ? AppTheme.primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
