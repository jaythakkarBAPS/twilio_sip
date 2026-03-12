import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  static const String _backendBaseUrl = 'https://apocryphal-elaboratively-nicholle.ngrok-free.dev';
  static const String _twilioCallerNumber = '+14472841621'; // Updated from .env

  static final TwilioService _instance = TwilioService._internal();
  factory TwilioService() => _instance;
  TwilioService._internal();

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Register the device with Twilio using a capability token from the backend
  Future<void> register(String identity) async {
    try {
      // 1. Request combined permissions for Android
      if (Platform.isAndroid) {
        final instance = TwilioVoice.instance;
        await instance.requestMicAccess();
        await instance.requestReadPhoneStatePermission();
        await instance.requestCallPhonePermission();
        await instance.requestReadPhoneNumbersPermission();
        await instance.requestManageOwnCallsPermission();
      } else {
        await requestMicrophonePermission();
      }

      // 2. Fetch token from backend
      final response = await http.get(Uri.parse('$_backendBaseUrl/token?identity=$identity'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String token = data['token'];
        
        // 3. Get FCM token for Android (required for registration)
        String? deviceToken;
        if (Platform.isAndroid) {
          deviceToken = await FirebaseMessaging.instance.getToken();
          print("FCM Token: $deviceToken");
          
          // 4. Register Phone Account for TelecomManager (Android Only)
          print("Registering Phone Account...");
          await TwilioVoice.instance.registerPhoneAccount();
          
          bool isEnabled = await TwilioVoice.instance.isPhoneAccountEnabled();
          print("Phone Account Enabled: $isEnabled");
          if (!isEnabled) {
            print("WARNING: Phone account is registered but NOT enabled. Opening settings...");
            await TwilioVoice.instance.openPhoneAccountSettings();
            print("Please enable the account for 'twilio_sip' in the settings screen that just opened.");
          }
        }
        
        // 5. Register the device with the token and deviceToken
        await TwilioVoice.instance.setTokens(accessToken: token, deviceToken: deviceToken);
        print("Twilio registration successful for $identity");
      } else {
        print('Failed to get Twilio token: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('Error registering Twilio: $e');
      print(stack);
    }
  }

  /// Place an outbound call
  Future<void> makeCall(String toNumber) async {
    if (Platform.isAndroid) {
      bool isEnabled = await TwilioVoice.instance.isPhoneAccountEnabled();
      if (!isEnabled) {
        print("ERROR: Cannot place call. Phone account is NOT enabled.");
        print("Opening settings... please enable the 'twilio_sip' account.");
        await TwilioVoice.instance.openPhoneAccountSettings();
        return;
      }
    }

    print("Placing call to $toNumber...");
    // The Twilio Voice SDK will send this "To" parameter to your backend's /make-call endpoint
    await TwilioVoice.instance.call.place(
      to: toNumber,
      from: _twilioCallerNumber,
    );
  }

  /// Hang up the current call
  Future<void> hangUp() async {
    await TwilioVoice.instance.call.hangUp();
  }

  /// Toggle speakerphone
  Future<void> toggleSpeaker(bool enabled) async {
    await TwilioVoice.instance.call.toggleSpeaker(enabled);
  }

  /// Toggle mute
  Future<void> toggleMute(bool enabled) async {
    await TwilioVoice.instance.call.toggleMute(enabled);
  }

  /// Stream to listen for call states (ringing, connected, etc)
  Stream<CallEvent> get callEvents => TwilioVoice.instance.callEventsListener;
}
