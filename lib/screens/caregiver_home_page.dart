import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _patientsSub;
  StreamSubscription<DocumentSnapshot>? _profileSub;

  List<_PatientStat> _patients = [];
  String _firstName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser!.uid;

    _profileSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      final fullName = (snap.data()?['fullName'] as String?) ?? '';
      if (mounted) setState(() => _firstName = fullName.split(' ').first);
    });

    _patientsSub = _db
        .collection('users')
        .doc(uid)
        .collection('patients')
        .snapshots()
        .listen(_onPatients);
  }

  Future<void> _onPatients(QuerySnapshot snap) async {
    final stats = <_PatientStat>[];
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final patientUid = doc.id;

      final logsSnap = await _db
          .collection('users')
          .doc(patientUid)
          .collection('doseLogs')
          .where('scheduledAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      int taken = 0, total = 0;
      for (final log in logsSnap.docs) {
        total++;
        if ((log.data()['status'] as String?) == 'taken') taken++;
      }
      final adherence = total == 0 ? 1.0 : taken / total;

      stats.add(_PatientStat(
        uid: patientUid,
        fullName: (data['fullName'] as String?) ?? 'Unknown',
        age: data['age'] as int?,
        adherence: adherence,
      ));
    }

    if (mounted) setState(() { _patients = stats; _loading = false; });
  }

  @override
  void dispose() {
    _patientsSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final total = _patients.length;
    final onTrack =
        _patients.where((p) => p.adherence >= 0.8).length;
    final needsAttention = total - onTrack;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 0),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                                'Hey ${_firstName.isNotEmpty ? _firstName : 'there'},',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _greeting(),
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          Icon(Icons.favorite_border,
                              size: 32, color: AppTheme.primaryColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Here's an overview of your circle's medication adherence",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.groups,
                              label: 'Total Users',
                              value: '$total',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_outline,
                              label: 'On Track',
                              value: '$onTrack',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.error_outline,
                              label: 'Need Attention',
                              value: '$needsAttention',
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('My Circle',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_patients.isEmpty)
                        const Text('No patients linked yet.',
                            style: TextStyle(color: Colors.black54)),
                      ..._patients.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PatientCard(
                              patient: p,
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed(
                                      '/caregiver-clients',
                                      arguments: p.uid),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _PatientStat {
  final String uid;
  final String fullName;
  final int? age;
  final double adherence;

  const _PatientStat({
    required this.uid,
    required this.fullName,
    this.age,
    required this.adherence,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 13)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final _PatientStat patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = patient.adherence;
    final statusColor = pct >= 0.8 ? AppTheme.primaryColor : Colors.redAccent;
    final statusText = pct >= 0.8 ? 'Perfect!' : 'Needs Attention';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  child: const Icon(Icons.person, size: 32, color: Colors.black38),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (patient.age != null)
                        Text('${patient.age} years old',
                            style: const TextStyle(color: Colors.black54)),
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
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Status : ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: statusColor)),
                Text(statusText,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
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
              onTap: () {}),
          _NavItem(
            icon: Icons.groups,
            label: selectedIndex == 1 ? 'Clients' : '',
            selected: selectedIndex == 1,
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('/caregiver-clients'),
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
