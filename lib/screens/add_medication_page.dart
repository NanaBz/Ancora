import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({Key? key}) : super(key: key);

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();

  String _selectedType = 'Tablet';
  String _selectedFrequency = 'Once Daily';
  String _selectedUnit = 'mg';

  DateTime? _startDate;
  DateTime? _endDate;
  List<TimeOfDay> _intakeTimes = [const TimeOfDay(hour: 8, minute: 0)];

  bool _saving = false;

  static const _types = [
    'Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Cream', 'Inhaler'
  ];
  static const _frequencies = [
    'Once Daily', 'Twice Daily', 'Three Times Daily', 'Custom'
  ];
  static const _units = ['mg', 'ml', 'g'];
  static const _freqCount = {
    'Once Daily': 1,
    'Twice Daily': 2,
    'Three Times Daily': 3,
    'Custom': 1,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String freq) {
    setState(() {
      _selectedFrequency = freq;
      if (freq != 'Custom') {
        final count = _freqCount[freq] ?? 1;
        while (_intakeTimes.length < count) {
          _intakeTimes.add(const TimeOfDay(hour: 12, minute: 0));
        }
        if (_intakeTimes.length > count) {
          _intakeTimes = _intakeTimes.take(count).toList();
        }
      }
    });
  }

  Future<void> _addCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _intakeTimes.add(picked));
  }

  void _removeTime(int index) {
    if (_intakeTimes.length > 1) {
      setState(() => _intakeTimes.removeAt(index));
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isStart
        ? (_startDate ?? today)
        : (_endDate ?? today.add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _intakeTimes[index],
    );
    if (picked != null) setState(() => _intakeTimes[index] = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final dosageStr = _dosageCtrl.text.trim();

    if (name.isEmpty || dosageStr.isEmpty) {
      _snack('Please enter medication name and dosage.');
      return;
    }
    final dosage = double.tryParse(dosageStr);
    if (dosage == null) {
      _snack('Dosage must be a number.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack('Please select start and end dates.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _snack('End date must be after start date.');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;

      final times = _intakeTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      final docRef =
          await db.collection('users').doc(uid).collection('medications').add({
        'name': name,
        'dosage': dosage,
        'unit': _selectedUnit,
        'medType': _selectedType,
        'frequency': _selectedFrequency,
        'intakeTimes': times,
        'startDate': Timestamp.fromDate(
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day)),
        'endDate': Timestamp.fromDate(
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.scheduleMedication(
        medId: docRef.id,
        medName: name,
        intakeTimes: times,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (mounted) {
        _snack('Medication added.');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Select date'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomNavBar(selectedIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 16.0),
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
                    Icon(Icons.favorite_border,
                        size: 32, color: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 24),
                _LabeledField(
                  icon: Icons.link,
                  label: 'Medication Name',
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Dosage',
                        child: TextField(
                          controller: _dosageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 28.0),
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        items: _units
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Medicine Type',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types
                      .map((type) => ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (_) =>
                                setState(() => _selectedType = type),
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedType == type
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.3)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Frequency',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _frequencies
                      .map((freq) => ChoiceChip(
                            label: Text(freq),
                            selected: _selectedFrequency == freq,
                            onSelected: (_) => _onFrequencyChanged(freq),
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedFrequency == freq
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.3)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Intake Times',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _intakeTimes.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(i),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black38),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text('Time ${i + 1}: ${_intakeTimes[i].format(context)}'),
                                  const Spacer(),
                                  const Icon(Icons.access_time, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_selectedFrequency == 'Custom' && _intakeTimes.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () => _removeTime(i),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_selectedFrequency == 'Custom')
                  TextButton.icon(
                    onPressed: _addCustomTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                  ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Treatment Duration',
                  icon: Icons.calendar_today,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black38),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _fmtDate(_startDate),
                              style: TextStyle(
                                color: _startDate == null
                                    ? Colors.black38
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black38),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _fmtDate(_endDate),
                              style: TextStyle(
                                color: _endDate == null
                                    ? Colors.black38
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Medication',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
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
  const _LabeledField(
      {required this.label, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(icon, color: AppTheme.primaryColor, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
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
            onTap: () =>
                Navigator.of(context).pushReplacementNamed('/history'),
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
