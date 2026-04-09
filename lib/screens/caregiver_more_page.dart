import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverMorePage extends StatefulWidget {
  const CaregiverMorePage({Key? key}) : super(key: key);

  @override
  State<CaregiverMorePage> createState() => _CaregiverMorePageState();
}

class _CaregiverMorePageState extends State<CaregiverMorePage> {
  bool missedDoseNotifications = true;
  bool emergencyAlerts = true;
  final _nameController = TextEditingController(text: 'Dr. Sarah Sasuke');
  final _ageController = TextEditingController(text: '32 years old');
  final _emailController = TextEditingController(text: 'sarahSasuke@gmail.com');

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                            'Profile & Settings',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.favorite_border, size: 28, color: AppTheme.primaryColor),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Caregiver Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _EditableProfileField(
                        label: 'Name',
                        controller: _nameController,
                      ),
                      _EditableProfileField(
                        label: 'Age',
                        controller: _ageController,
                      ),
                      _EditableProfileField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {}); // In a real app, save changes to backend
                          },
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                          Icon(Icons.alarm, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          const Text('Alert Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: missedDoseNotifications,
                        onChanged: (val) => setState(() => missedDoseNotifications = val),
                        activeColor: AppTheme.primaryColor,
                        title: const Text('Missed Dose Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Receive a notification when a user misses a scheduled dose'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: emergencyAlerts,
                        onChanged: (val) => setState(() => emergencyAlerts = val),
                        activeColor: AppTheme.primaryColor,
                        title: const Text('Emergency Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Receive urgent alerts for consecutive missed doses'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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


class _EditableProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  const _EditableProfileField({required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text('$label :', style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
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
          _CaregiverNavBarItem(
            icon: Icons.home,
            label: selectedIndex == 0 ? 'Home' : '',
            selected: selectedIndex == 0,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/caregiver-home');
            },
          ),
          _CaregiverNavBarItem(
            icon: Icons.groups,
            label: selectedIndex == 1 ? 'Clients' : '',
            selected: selectedIndex == 1,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/caregiver-clients');
            },
          ),
          _CaregiverNavBarItem(
            icon: Icons.person_add,
            label: selectedIndex == 2 ? 'Add User' : '',
            selected: selectedIndex == 2,
            onTap: () {
              if (selectedIndex != 2) {
                Navigator.of(context).pushReplacementNamed('/caregiver-add-user');
              }
            },
          ),
          _CaregiverNavBarItem(
            icon: Icons.menu,
            label: selectedIndex == 3 ? 'More' : '',
            selected: selectedIndex == 3,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CaregiverNavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CaregiverNavBarItem({
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
          Icon(icon, color: selected ? AppTheme.primaryColor : Colors.white, size: 28),
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
