// lib/screens/role_specific_welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:p1/screens/patient_health_questionnaire.dart';
import 'package:p1/screens/doctor_professional_details.dart';
import 'package:p1/theme.dart';

class RoleSpecificWelcomeScreen extends StatelessWidget {
  final String userRole;
  final String nickname;

  const RoleSpecificWelcomeScreen({
    super.key,
    required this.userRole,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    bool isDoctor = userRole == 'Doctor';
    String title = isDoctor ? 'Welcome, Dr. $nickname!' : 'Welcome, $nickname!';
    String message = isDoctor
        ? 'We\'re excited to have you on board. Let\'s set up your professional profile to connect you with patients seeking your expertise.'
        : 'We’re going to ask you some health-related questions to personalize your health journey for your unique needs.';
    String buttonText = isDoctor ? 'Setup Profile' : 'Start Questionnaire';
    String imagePath = isDoctor ? 'assets/doctor_welcome.jpg' : 'assets/patient_welcome.png';
    // Ensure these assets are in your pubspec.yaml and assets folder

    VoidCallback onPressedAction = () {
      if (isDoctor) {
        Navigator.pushReplacement( // Use pushReplacement so they can't go back to welcome
          context,
          MaterialPageRoute(builder: (context) => const DoctorProfessionalDetails()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientHealthQuestionnaire()),
        );
      }
    };

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                imagePath,
                height: MediaQuery.of(context).size.height * 0.35,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    isDoctor ? Icons.medical_services_outlined : Icons.person_search_outlined,
                    size: 100,
                    color: AppColors.primary.withOpacity(0.5),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.dark,
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onPressedAction,
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
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}