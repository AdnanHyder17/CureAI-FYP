// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // For Firebase initialization
import 'package:p1/screens/splash_screen.dart'; // Your app's splash screen
import 'package:p1/firebase_options.dart'; // Generated Firebase configuration
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions
import 'package:p1/theme.dart'; // Your app's theme (AppColors)

// Asynchronously requests necessary permissions for camera and microphone.
// This is crucial for video call functionalities.
Future<void> requestCorePermissions() async {
  // Request multiple permissions at once.
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
    // Add any other core permissions your app needs at startup here
  ].request();

  // Handle camera permission status
  if (statuses[Permission.camera] == PermissionStatus.denied) {
    debugPrint("Camera permission was denied by the user.");
    // You might want to show a dialog explaining why the permission is needed
  } else if (statuses[Permission.camera] == PermissionStatus.permanentlyDenied) {
    debugPrint("Camera permission was permanently denied. Opening app settings.");
    await openAppSettings(); // Prompts the user to open settings to grant permission
  }

  // Handle microphone permission status
  if (statuses[Permission.microphone] == PermissionStatus.denied) {
    debugPrint("Microphone permission was denied by the user.");
  } else if (statuses[Permission.microphone] == PermissionStatus.permanentlyDenied) {
    debugPrint("Microphone permission was permanently denied. Opening app settings.");
    // Only open settings once if multiple are permanently denied
    if (statuses[Permission.camera] != PermissionStatus.permanentlyDenied) {
      await openAppSettings();
    }
  }

  // Log granted permissions for debugging
  if (await Permission.camera.isGranted) {
    debugPrint("Camera permission granted.");
  }
  if (await Permission.microphone.isGranted) {
    debugPrint("Microphone permission granted.");
  }
}

// The main entry point for the application.
void main() async {
  // Ensures that plugin services are initialized before runApp() is called.
  // Required for Firebase.initializeApp() and other platform-specific code.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the application.
  // It's crucial to await this before using any Firebase services.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Uses firebase_options.dart
    );
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    // Log any errors during Firebase initialization.
    // In a production app, you might want to report this to an error tracking service.
    debugPrint("Firebase initialization error: $e");
    // Optionally, you could show an error screen or prevent the app from starting
    // if Firebase is critical for core functionality.
  }

  // Request essential permissions after Firebase is initialized (or in parallel if not dependent)
  // Doing this early can improve user experience for features requiring these permissions.
  // However, it's often better to request permissions contextually when the feature is first used.
  // For core features like calling, requesting early might be acceptable.
  // await requestCorePermissions(); // You can call this here or on the first screen that needs it.

  // Run the Flutter application.
  runApp(const CureAIApp());
}

// The root widget of the CureAI application.
class CureAIApp extends StatelessWidget {
  const CureAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is the base widget for a Material Design application.
    return MaterialApp(
      title: 'CureAI', // The title of the application (used by the OS).
      debugShowCheckedModeBanner: false, // Hides the debug banner in the top-right corner.

      // Define the application's theme.
      theme: ThemeData(
        primaryColor: AppColors.primary, // Primary color for the app.
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          // You can define more colors like surface, background, onPrimary etc.
        ),
        scaffoldBackgroundColor: AppColors.light, // Default background for Scaffolds.
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0, // Flat app bar design
          iconTheme: IconThemeData(color: AppColors.white), // Icons in AppBar (e.g., back button)
          titleTextStyle: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600)
            )
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.gray.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.gray.withOpacity(0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: AppColors.error, width: 1.8),
          ),
          filled: true,
          fillColor: AppColors.white.withOpacity(0.9),
          labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.7)),
          hintStyle: TextStyle(color: AppColors.gray.withOpacity(0.8)),
          prefixIconColor: AppColors.secondary,
        ),
        // Use a modern font if desired (e.g., GoogleFonts.poppinsTextTheme())
        // fontFamily: 'YourAppFont', // Make sure to add the font to pubspec.yaml and assets
        visualDensity: VisualDensity.adaptivePlatformDensity, // Adapts UI to platform density.
      ),

      // The initial route/screen of the application.
      home: const SplashScreen(),

      // Builder to wrap the app with MediaQuery to control text scaling.
      // This ensures that the app's text size doesn't change with system font size settings,
      // maintaining a consistent UI. This can be an accessibility concern, so use judiciously.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Disables font scaling.
          ),
          child: child!, // The child is the rest of your app.
        );
      },
    );
  }
}
