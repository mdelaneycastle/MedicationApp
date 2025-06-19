import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  void _navigateToCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Reminder'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _openSettings(context),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No meds taken today'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToCamera(context),
              child: Text('Take Meds & Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}