import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize awesome_notifications with the SAME channel key
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'force_quit_channel',
      // MUST match Kotlin CHANNEL_KEY
      channelName: 'Force Quit Alerts',
      channelDescription: 'Notification when app is closed',
      importance: NotificationImportance.High,
      defaultColor: Colors.blue,
    ),
    // Add your other channels here
  ]);

  // Request permission
  await AwesomeNotifications().isNotificationAllowed().then((allowed) {
    if (!allowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.flutter_app_close/service');

  @override
  void initState() {
    super.initState();
    _startService();
    _setupNotificationListeners();
  }

  Future<void> _startService() async {
    try {
      await platform.invokeMethod('startService');
    } on PlatformException catch (e) {
      debugPrint('Service start failed: ${e.message}');
    }
  }

  void _setupNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    // Handle notification tap — app is already reopening
    debugPrint('Notification tapped: ${action.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Force Quit Demo')),
      body: const Center(
        child: Text(
          'Swipe app away → get a notification',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
