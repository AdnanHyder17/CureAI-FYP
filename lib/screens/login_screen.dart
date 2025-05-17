// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p1/screens/signup_screen.dart';
import 'package:p1/screens/homeScreen.dart'; // Patient's main screen
import 'package:p1/screens/doctor_dashboard_screen.dart'; // Doctor's main screen
import 'package:p1/screens/role_specific_welcome_screen.dart'; // For incomplete profiles
import 'package:p1/theme.dart';
import 'package:p1/widgets/custom_textfield.dart'; // Assuming you might create this
import 'package:p1/widgets/loading_indicator.dart'; // Assuming you might create this

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

        if (!userDoc.exists || userDoc.data() == null) {
          // Should not happen if signup is correct, but handle defensively
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found. Please sign up again or contact support.'), backgroundColor: AppColors.error),
          );
          await _auth.signOut(); // Sign out inconsistent user
          setState(() => _isLoading = false);
          return;
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final String role = userData['role'] as String? ?? 'Patient';
        final String nickname = userData['nickname'] as String? ?? 'User';

        bool isProfileComplete = userData['isProfileSetupComplete'] as bool? ?? false;

        if (mounted) {

          if (role == 'Doctor') {
            // **** ADD THIS SECTION FOR DOCTOR STATUS UPDATE ****
            try {
              await _firestore.collection('doctors').doc(userCredential.user!.uid).set({
                'status': 'online',
                'callStatus': 'available', // Doctor is available for calls upon login
                'lastStatusUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)); // merge:true to not overwrite other details
              debugPrint("Doctor ${userCredential.user!.uid} status set to online/available.");
            } catch (e) {
              debugPrint("Error updating doctor status on login: $e");
              // Non-fatal, proceed with login flow
            }
            // **** END OF ADDED SECTION ****
          }

          if (isProfileComplete) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => role == 'Doctor' ? const DoctorDashboardScreen() : const HomeScreen(),
              ),
                  (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => RoleSpecificWelcomeScreen(userRole: role, nickname: nickname),
              ),
                  (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.light,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.05),
                Image.asset(
                  'assets/CureAI_LogoName_PNG.png', // Ensure this asset is in your pubspec and assets folder
                  height: screenHeight * 0.15,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.medical_services_outlined, size: 80, color: AppColors.primary),
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue your health journey.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dark.withOpacity(0.7)),
                ),
                SizedBox(height: screenHeight * 0.05),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      CustomTextField( // Replace with your custom widget or TextFormField
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.secondary,
                          ),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const LoadingIndicator() // Replace with your custom widget or CircularProgressIndicator
                          : ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.dark.withOpacity(0.8)),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



