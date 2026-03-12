import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/call_screen.dart';
import 'services/twilio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required for FCM)
  await Firebase.initializeApp();
  
  // Initialize Twilio Service and register
  final twilio = TwilioService();
  
  // Request microphone permission on setup
  await twilio.requestMicrophonePermission();
  
  // Register with Twilio
  await twilio.register('agent_001');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twilio Call Center',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      debugShowCheckedModeBanner: false,
      home: CallScreen(),
    );
  }
}
