import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverAddUserPage extends StatefulWidget {
  const CaregiverAddUserPage({Key? key}) : super(key: key);

  @override
  State<CaregiverAddUserPage> createState() => _CaregiverAddUserPageState();
}

class _CaregiverAddUserPageState extends State<CaregiverAddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeCtrl.text.trim();
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final me = FirebaseAuth.instance.currentUser!;

      final idxSnap =
          await db.collection('displayIdIndex').doc(code).get();
      if (!idxSnap.exists) {
        _snack('No user found with ID $code.');
        return;
      }

      final patientUid = idxSnap.data()!['uid'] as String;

      if (patientUid == me.uid) {
        _snack('You cannot add yourself.');
        return;
      }

      final alreadyLinked = await db
          .collection('users')
          .doc(patientUid)
          .collection('caregivers')
          .doc(me.uid)
          .get();
      if (alreadyLinked.exists) {
        _snack('You are already linked to this patient.');
        return;
      }

      final patientSnap =
          await db.collection('users').doc(patientUid).get();
      if (!patientSnap.exists) {
        _snack('Patient profile not found.');
        return;
      }
      final patientData = patientSnap.data()!;
      final patientName =
          (patientData['fullName'] as String?) ?? 'Unknown';

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm'),
          content: Text('Link with $patientName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final batch = db.batch();
      batch.set(
        db
            .collection('users')
            .doc(patientUid)
            .collection('caregivers')
            .doc(me.uid),
        {'linkedAt': FieldValue.serverTimestamp()},
      );
      batch.set(
        db
            .collection('users')
            .doc(me.uid)
            .collection('patients')
            .doc(patientUid),
        {
          'linkedAt': FieldValue.serverTimestamp(),
          'fullName': patientData['fullName'],
          'displayId': patientData['displayId'],
          'photoURL': patientData['photoURL'],
          'age': patientData['age'],
        },
      );
      await batch.commit();

      _codeCtrl.clear();
      _snack('$patientName added to your circle.');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
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
                            'Add Client',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add new clients and track their progress.',
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: "Patient's 4-digit ID",
                            hintText: 'eg. 5953',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length != 4) {
                              return 'Enter exactly 4 digits';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Must be numeric';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: _loading ? null : _addClient,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Text('Add',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onPressed: () {
                              _formKey.currentState?.reset();
                              _codeCtrl.clear();
                            },
                            child: const Text('Reset',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        color: Colors.black,
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
            onTap: () => Navigator.of(context)
                .pushReplacementNamed('/caregiver-clients'),
          ),
          _NavItem(
            icon: Icons.person_add,
            label: selectedIndex == 2 ? 'Add User' : '',
            selected: selectedIndex == 2,
            onTap: () {},
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
