import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:p1/screens/splash_screen.dart';
import 'package:p1/firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
  ].request();

  if (statuses[Permission.camera]!.isPermanentlyDenied || statuses[Permission.microphone]!.isPermanentlyDenied) {
    // User has permanently denied permission, open app settings
    openAppSettings();
  } else {
    if (!await Permission.camera.isGranted) {
      print("Camera permission not granted");
    }
    if (!await Permission.microphone.isGranted) {
      print("Microphone permission not granted");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase/Notification initialization error: $e");
  }

  // Run the app with error handling
  runApp(const CureAIApp());
}

class CureAIApp extends StatelessWidget {
  const CureAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CureAI',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}

