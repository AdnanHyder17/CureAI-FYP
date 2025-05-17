// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p1/screens/login_screen.dart';
import 'package:p1/screens/homeScreen.dart'; // Patient's main screen
import 'package:p1/screens/doctor_dashboard_screen.dart'; // Doctor's main screen
import 'package:p1/screens/role_specific_welcome_screen.dart'; // New combined welcome
import 'package:p1/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Ensure some delay for splash visibility, even if checks are fast
    await Future.delayed(const Duration(seconds: 3));

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // No user logged in, go to Login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // User is logged in, check their role and profile completion
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        // User document doesn't exist, something is wrong, perhaps force logout/login
        if (mounted) {
          await FirebaseAuth.instance.signOut(); // Clean up inconsistent state
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String role = userData['role'] as String? ?? 'Patient';
      final String nickname = userData['nickname'] as String? ?? 'User';

      bool isProfileComplete = userData['isProfileSetupComplete'] as bool? ?? false;

      if (mounted) {
        if (isProfileComplete) {
          // Profile complete, go to the respective main screen
          if (role == 'Doctor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
            );
          } else { // Patient
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Profile incomplete, go to the role-specific welcome screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RoleSpecificWelcomeScreen(
                userRole: role,
                nickname: nickname,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error during splash screen navigation logic: $e");
      // Fallback to login screen on error
      if (mounted) {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Your App Logo
              Image.asset(
                'assets/CureAI_Logo_PNG.png',
                width: MediaQuery.of(context).size.width * 0.6,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medical_services_outlined,
                    size: 120,
                    color: AppColors.white,
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'CureAI',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your Health, Our Priority',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 30, // Smaller, more subtle
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.light),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}