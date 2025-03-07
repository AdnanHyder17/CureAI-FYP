import 'package:flutter/material.dart';
import 'doctor_professional_details.dart';
import 'package:p1/theme.dart';

class DoctorWelcomeScreen extends StatelessWidget {
  final String nickname;

  const DoctorWelcomeScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: Text(
          'Welcome, Dr. $nickname',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Doctor Illustration
            Image.asset(
                'assets/doctor_welcome.jpg', // Ensure this asset exists
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),

            // Welcome Message
            Text(
              'We\'re excited to have you on board. Let\'s set up your professional profile to connect you with patients seeking your expertise.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.dark,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),

            // Get Started Button
            ElevatedButton(
              onPressed: () {
                // Navigate to Doctor Professional Details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorProfessionalDetails(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 2,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}