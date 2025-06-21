import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'medsmanager.dart' show MedicationManagerScreen;
import 'models/medication.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = "1234";
  bool _authenticated = false;
  String? _errorText;

  void _checkPin() {
    if (_pinController.text == _correctPin) {
      setState(() {
        _authenticated = true;
        _errorText = null;
      });
    } else {
      setState(() {
        _errorText = "Incorrect PIN";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _authenticated
          ? AlarmSettings()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Enter 4-digit PIN to access settings"),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: "••••",
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkPin,
                    child: const Text("Unlock"),
                  ),
                ],
              ),
            ),
    );
  }
}

class AlarmSettings extends StatefulWidget {
  @override
  State<AlarmSettings> createState() => _AlarmSettingsState();
}

class _AlarmSettingsState extends State<AlarmSettings> {
  int _timesPerDay = 1;
  List<TimeOfDay?> _selectedTimes = [null];
  List<List<Medication>> _medicationsPerReminder = [[]];
  List<Medication> _allMeds = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medList = prefs.getStringList('medications') ?? [];
    final meds = medList.map((m) => Medication.fromMap(json.decode(m))).toList();
    setState(() {
      _allMeds = meds;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final timesPerDay = prefs.getInt('timesPerDay') ?? 1;
    final storedTimes = prefs.getStringList('selectedTimes') ?? [];
    final storedMeds = prefs.getStringList('medsPerReminder') ?? [];

    setState(() {
      _timesPerDay = timesPerDay;
      _selectedTimes = List.generate(timesPerDay, (i) {
        if (i < storedTimes.length && storedTimes[i].isNotEmpty) {
          final parts = storedTimes[i].split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        return null;
      });
      _medicationsPerReminder = List.generate(timesPerDay, (i) {
        if (i < storedMeds.length && storedMeds[i].isNotEmpty) {
          final decoded = json.decode(storedMeds[i]) as List;
          return decoded.map((e) => Medication.fromMap(e)).toList();
        }
        return [];
      });
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timesPerDay', _timesPerDay);
    final timeStrings = _selectedTimes.map((t) => t == null ? "" : '${t.hour}:${t.minute}').toList();
    final medsStrings = _medicationsPerReminder.map((list) {
      return json.encode(list.map((m) => m.toMap()).toList());
    }).toList();
    await prefs.setStringList('selectedTimes', timeStrings);
    await prefs.setStringList('medsPerReminder', medsStrings);
  }

  void _updateTimes(int newCount) {
    setState(() {
      _timesPerDay = newCount;
      _selectedTimes = List.generate(
        newCount,
        (i) => _selectedTimes.length > i ? _selectedTimes[i] : null,
      );
      _medicationsPerReminder = List.generate(
        newCount,
        (i) => _medicationsPerReminder.length > i ? _medicationsPerReminder[i] : [],
      );
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  Future<void> _selectMedsForReminder(int index) async {
    final selected = Set<Medication>.from(_medicationsPerReminder[index]);
    final result = await showDialog<Set<Medication>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Medications"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _allMeds.map((med) {
                final isSelected = selected.contains(med);
                return CheckboxListTile(
                  title: Text("${med.name} - ${med.dosageMg}mg"),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      val == true ? selected.add(med) : selected.remove(med);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, selected), child: const Text("Save")),
        ],
      ),
    );

    if (result != null) {
      setState(() => _medicationsPerReminder[index] = result.toList());
    }
  }

  Future<void> _saveAndSchedule() async {
    await NotificationService.cancelAll();
    for (int i = 0; i < _selectedTimes.length; i++) {
      final time = _selectedTimes[i];
      if (time != null) {
        final meds = _medicationsPerReminder[i];
        final msg = meds.isEmpty
            ? "Time to take dose ${i + 1}"
            : meds.map((m) => "${m.name} (${m.dosageMg}mg)").join(", ");
        await NotificationService.scheduleDailyNotification(
          i,
          time,
          "Take: $msg",
        );
      }
    }
    await _saveSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminders scheduled and saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("How many times a day do you take your meds?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButton<int>(
            value: _timesPerDay,
            onChanged: (value) => value != null ? _updateTimes(value) : null,
            items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} times per day'))),
          ),
          const SizedBox(height: 20),
          ...List.generate(_timesPerDay, (i) {
            final time = _selectedTimes[i];
            final meds = _medicationsPerReminder[i];
            return ListTile(
              title: Text("Reminder ${i + 1}"),
              subtitle: Text(time == null ? "No time selected" : time.format(context)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.access_time), onPressed: () => _pickTime(i)),
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _selectMedsForReminder(i)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveAndSchedule,
            child: const Text("Save Settings"),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MedicationManagerScreen()),
              );
              await _loadMedications(); // 👈 reload after returning
            },
            icon: const Icon(Icons.medical_services),
            label: const Text("Manage Medications"),
          ),
        ],
      ),
    );
  }
}