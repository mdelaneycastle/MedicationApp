import 'package:flutter/material.dart';
import 'dart:async';
import 'camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestCorePermissions();
  await NotificationService.init();
  runApp(MyApp());
}

Future<void> _requestCorePermissions() async {
  await Permission.notification.request();
  await Permission.scheduleExactAlarm.request();
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isNotificationPermissionGranted = false;
  bool _isExactAlarmPermissionGranted = false;
  bool _permissionsChecked = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;

    setState(() {
      _isNotificationPermissionGranted = notifStatus.isGranted;
      _isExactAlarmPermissionGranted = alarmStatus.isGranted;
      _permissionsChecked = true;
    });

    print('MyApp - Notification permission: $notifStatus');
    print('MyApp - Exact alarm permission: $alarmStatus');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Builder(
        builder: (BuildContext builderContext) {
          if (!_permissionsChecked) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final bool _isAnyPermissionMissing =
              !_isNotificationPermissionGranted || !_isExactAlarmPermissionGranted;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Medication Reminder'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      builderContext,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ).then((_) {
                      _checkPermissions();
                    });
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAnyPermissionMissing)
                    Card(
                      color: Colors.red.shade100,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Permissions Required!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!_isNotificationPermissionGranted)
                              _buildPermissionNotice(
                                title: "🔔 Notification Permission Denied:",
                                message:
                                    "Please enable notifications for this app in your phone settings to receive reminders.",
                              ),
                            if (!_isExactAlarmPermissionGranted)
                              _buildPermissionNotice(
                                title: "⏰ Exact Alarm Permission Denied:",
                                message:
                                    "This is crucial for accurate reminder delivery. Please enable 'Alarms & reminders'.",
                              ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await openAppSettings();
                                _checkPermissions();
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text("Go to App Settings"),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _showHonorHuaweiGuidance(builderContext);
                              },
                              child: const Text("Troubleshoot Huawei/Honor Notifications"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Text(
                    "Welcome to your Medication Reminder!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Set up your daily medication reminders in the settings or take your medication now.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        builderContext,
                        MaterialPageRoute(builder: (_) => CameraScreen()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Medication (Open Camera)"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final oneMinuteLater = TimeOfDay(
                        hour: now.add(const Duration(minutes: 1)).hour,
                        minute: now.add(const Duration(minutes: 1)).minute,
                      );

                      await NotificationService.scheduleDailyNotification(
                        2,
                        oneMinuteLater,
                        "Time to take your meds! 💊",
                      );

                      setState(() {
                        _countdown = 60;
                      });

                      _countdownTimer?.cancel();
                      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                        if (_countdown <= 0) {
                          timer.cancel();
                        } else {
                          setState(() {
                            _countdown--;
                          });
                        }
                      });

                      ScaffoldMessenger.of(builderContext).showSnackBar(
                        const SnackBar(content: Text("⏰ Reminder set for 1 minute from now")),
                      );
                    },
                    child: const Text("Trigger Reminder in 1 Minute"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      NotificationService.showTestNotification();
                    },
                    child: const Text("Send Test Notification"),
                  ),
                  if (_countdown > 0)
                    Text(
                      "⏳ Notification in $_countdown seconds",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  else
                    const Text("✅ Waiting for notification...", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final pendingNotifications =
                          await NotificationService.getPendingNotifications();

                      if (pendingNotifications.isEmpty) {
                        ScaffoldMessenger.of(builderContext).showSnackBar(
                          const SnackBar(content: Text("No pending notifications.")),
                        );
                      } else {
                        showDialog(
                          context: builderContext,
                          builder: (context) => AlertDialog(
                            title: const Text("Scheduled Reminders"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: pendingNotifications
                                  .map((p) => Text('ID: ${p.id}, Title: ${p.title ?? "No Title"}'))
                                  .toList(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text("View Pending Notifications"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionNotice({required String title, required String message}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(message),
        ],
      ),
    );
  }

  Future<void> _showHonorHuaweiGuidance(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Important for Honor/Huawei Users!"),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Your device has strict battery optimization settings that can block reminders."),
                SizedBox(height: 10),
                Text("Please follow these steps to ensure reminders work:"),
                SizedBox(height: 5),
                Text("1. Go to your phone's Settings > Battery > App launch."),
                Text("2. Find 'Medication Reminder' and turn 'Manage automatically' OFF."),
                Text("3. In the pop-up, enable 'Auto-launch', 'Secondary launch', and 'Run in background'."),
                SizedBox(height: 10),
                Text("You might also need to check: Phone Manager app > Battery > App launch / Lock screen cleanup and ensure the app is protected."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got It'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Go to App Settings'),
              onPressed: () {
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}