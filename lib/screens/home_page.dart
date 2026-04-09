import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  final String firstName;
  const HomePage({Key? key, required this.firstName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNavBar(selectedIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Today's Progress",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '100%',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
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
                              value: 1.0,
                              strokeWidth: 4,
                              backgroundColor: AppTheme.featureCardColor,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                          const Text('100%', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                _ScheduleCard(
                  medicine: 'Paracetamol',
                  dosage: '100 mg',
                  count: '2 Tablets',
                  status: 'Upcoming',
                  statusColor: Colors.redAccent,
                  actionLabel: 'Take',
                  actionColor: Colors.green,
                ),
                const SizedBox(height: 12),
                _ScheduleCard(
                  medicine: 'Anti-Biotic',
                  dosage: '150 mg',
                  count: '2 Tablets',
                  status: 'Soon',
                  statusColor: Colors.amber,
                  actionLabel: '',
                  actionColor: Colors.transparent,
                ),
                const SizedBox(height: 12),
                _ScheduleCard(
                  medicine: 'Anti-Biotic',
                  dosage: '150 mg',
                  count: '2 Tablets',
                  status: 'Completed',
                  statusColor: Colors.green,
                  actionLabel: '',
                  actionColor: Colors.transparent,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String medicine;
  final String dosage;
  final String count;
  final String status;
  final Color statusColor;
  final String actionLabel;
  final Color actionColor;

  const _ScheduleCard({
    required this.medicine,
    required this.dosage,
    required this.count,
    required this.status,
    required this.statusColor,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        border: Border.all(color: statusColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                medicine,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Dosage  -  ', style: TextStyle(color: Colors.black54)),
              Text(dosage, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (actionLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBarItem(
            icon: Icons.home,
            label: selectedIndex == 0 ? 'Home' : '',
            selected: selectedIndex == 0,
            onTap: () {},
          ),
          _NavBarItem(
            icon: Icons.calendar_today,
            label: selectedIndex == 1 ? 'History' : '',
            selected: selectedIndex == 1,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/history');
            },
          ),
          _NavBarItem(
            icon: Icons.add,
            label: selectedIndex == 2 ? 'Add' : '',
            selected: selectedIndex == 2,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/add');
            },
          ),
          _NavBarItem(
            icon: Icons.menu,
            label: selectedIndex == 3 ? 'More' : '',
            selected: selectedIndex == 3,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/more');
            },
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
