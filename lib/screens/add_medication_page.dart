import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({Key? key}) : super(key: key);

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  String selectedType = 'Tablet';
  String selectedFrequency = 'Once Daily';
  String selectedUnit = 'mg';

  final List<String> types = [
    'Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Cream', 'Inhaler'
  ];
  final List<String> frequencies = [
    'Once Daily', 'Twice Daily', 'Three Times Daily', 'Custom'
  ];
  final List<String> units = ['mg', 'ml', 'g'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNavBar(selectedIndex: 2),
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
                    Text(
                      'Add Medication',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.favorite_border, size: 32, color: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 24),
                _LabeledField(
                  icon: Icons.link,
                  label: 'Medication Name',
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'eg. Paracetamol',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Dosage',
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'eg. 500',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedUnit,
                      items: units.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedUnit = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Medicine Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((type) => ChoiceChip(
                    label: Text(type),
                    selected: selectedType == type,
                    onSelected: (_) => setState(() => selectedType = type),
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selectedType == type ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: frequencies.map((freq) => ChoiceChip(
                    label: Text(freq),
                    selected: selectedFrequency == freq,
                    onSelected: (_) => setState(() => selectedFrequency = freq),
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selectedFrequency == freq ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Intake Times',
                  icon: Icons.access_time,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'eg. 08:00 am',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Treatment Duration',
                  icon: Icons.calendar_today,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'eg. 27/03/2026 Start Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'eg. 05/04/2026 End Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget child;
  const _LabeledField({required this.label, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, color: AppTheme.primaryColor, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
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
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
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
            onTap: () {},
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
