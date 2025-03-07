import 'package:flutter/material.dart';
import 'patient_health_questionnaire.dart';
import 'package:p1/theme.dart';

class PatientWelcomeScreen extends StatelessWidget {
  final String nickname;

  const PatientWelcomeScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: Text(
          'Welcome, $nickname',
          overflow: TextOverflow.ellipsis, // Prevents long names from breaking layout
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Robot Illustration
            Flexible(
              child: Image.asset(
                'assets/patient_welcome.png', // Ensure this asset exists
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Welcome Message
            Text(
              'We’re going to ask you some health-related questions to personalize your health journey for your unique needs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.dark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),

            // Start Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientHealthQuestionnaire(),
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
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}