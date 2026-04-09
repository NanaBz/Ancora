import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _CaregiverBottomNavBar(selectedIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                        Text(
                          'Hey Dr Sarah,',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Good Morning',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.favorite_border, size: 32, color: AppTheme.primaryColor),
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
                      child: _CaregiverStatCard(
                        icon: Icons.groups,
                        label: 'Total Users',
                        value: '2',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CaregiverStatCard(
                        icon: Icons.check_circle_outline,
                        label: 'On Track',
                        value: '1',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CaregiverStatCard(
                        icon: Icons.error_outline,
                        label: 'Need Attention',
                        value: '1',
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('My Circle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _CaregiverUserCard(
                  name: 'John Davies Jr',
                  age: '22 years old',
                  percent: 1.0,
                  status: 'Perfect!',
                  statusColor: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                _CaregiverUserCard(
                  name: 'Yaw Spinx',
                  age: '41 years old',
                  percent: 0.5,
                  status: 'Needs Attention',
                  statusColor: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaregiverStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CaregiverStatCard({required this.icon, required this.label, required this.value, required this.color});

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
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaregiverUserCard extends StatelessWidget {
  final String name;
  final String age;
  final double percent;
  final String status;
  final Color statusColor;
  const _CaregiverUserCard({required this.name, required this.age, required this.percent, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(age, style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Status : ', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ],
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
            onTap: () {},
          ),
          _CaregiverNavBarItem(
            icon: Icons.groups,
            label: selectedIndex == 1 ? 'Clients' : '',
            selected: selectedIndex == 1,
            onTap: () {
              if (selectedIndex != 1) {
                Navigator.of(context).pushReplacementNamed('/caregiver-clients');
              }
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
            onTap: () {
              if (selectedIndex != 3) {
                Navigator.of(context).pushReplacementNamed('/caregiver-more');
              }
            },
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
