import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'models/medication.dart';

class MedicationManagerScreen extends StatefulWidget {
  const MedicationManagerScreen({super.key});

  @override
  State<MedicationManagerScreen> createState() => _MedicationManagerScreenState();
}

class _MedicationManagerScreenState extends State<MedicationManagerScreen> {
  List<Medication> _medications = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final meds = prefs.getStringList('medications') ?? [];
    setState(() {
      _medications = meds.map((e) => Medication.fromMap(json.decode(e))).toList();
    });
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _medications.map((m) => json.encode(m.toMap())).toList();
    await prefs.setStringList('medications', encoded);
  }

  void _addMedication() {
    final name = _nameController.text.trim();
    final mg = int.tryParse(_mgController.text.trim());
    if (name.isNotEmpty && mg != null) {
      setState(() {
        _medications.add(Medication(name: name, dosageMg: mg));
        _nameController.clear();
        _mgController.clear();
      });
      _saveMedications();
    }
  }

  void _deleteMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
    _saveMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Medications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
            ),
            TextField(
              controller: _mgController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dosage (mg)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addMedication,
              child: const Text("Add Medication"),
            ),
            const Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _medications.length,
                itemBuilder: (context, index) {
                  final Medication med = _medications[index];
                  return ListTile(
                    title: Text('${med.name} (${med.dosageMg}mg)'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteMedication(index),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}