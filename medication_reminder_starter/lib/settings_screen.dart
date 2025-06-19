import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';



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

appBar: AppBar(title: Text("Settings")),

body: _authenticated

? AlarmSettings()

: Padding(

padding: const EdgeInsets.all(24.0),

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: [

Text("Enter 4-digit PIN to access settings",

style: TextStyle(fontSize: 16)),

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

SizedBox(height: 16),

ElevatedButton(

onPressed: _checkPin,

child: Text("Unlock"),

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



void _updateTimes(int newCount) {

setState(() {

_timesPerDay = newCount;

_selectedTimes = List.generate(

newCount,

(i) => _selectedTimes.length > i ? _selectedTimes[i] : null,

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



@override

Widget build(BuildContext context) {

return Padding(

padding: const EdgeInsets.all(16),

child: ListView(

children: [

Text(

"How many times a day do you take your meds?",

style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

),

SizedBox(height: 10),

DropdownButton<int>(

value: _timesPerDay,

onChanged: (value) {

if (value != null) _updateTimes(value);

},

items: List.generate(5, (index) {

final val = index + 1;

return DropdownMenuItem(

value: val,

child: Text('$val times per day'),

);

}),

),

SizedBox(height: 20),

...List.generate(_timesPerDay, (i) {

final time = _selectedTimes[i];

return ListTile(

title: Text("Reminder ${i + 1}"),

subtitle: Text(

time == null ? "No time selected" : time.format(context),

),

trailing: Icon(Icons.access_time),

onTap: () => _pickTime(i),

);

}),

SizedBox(height: 20),

ElevatedButton(

onPressed: () async {

print("Save button pressed");

await NotificationService.cancelAll();



for (int i = 0; i < _selectedTimes.length; i++) {

final time = _selectedTimes[i];

if (time != null) {

print("Scheduling reminder $i at ${time.format(context)}");

await NotificationService.scheduleDailyNotification(

i,

time,

"Time to take dose ${i + 1}",

);

}

}



ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text("Reminders scheduled!")),

);

},

child: Text("Save Settings"),

),

SizedBox(height: 10),

ElevatedButton(

onPressed: () async {

await NotificationService.showTestNotification();

},

child: Text("Send Test Notification"),

),

],

),

);

}

}

