// lib/screens/doctor_patients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:p1/theme.dart';

class DoctorPatientsListScreen extends StatelessWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar can be removed
      // appBar: AppBar(title: Text('My Patients'), backgroundColor: AppColors.primary),
      body: Center(
        // TODO: Implement list of patients consulted by this doctor
        // Fetch from appointments, get unique patientIds, then fetch patient details
        child: Text('Doctor Patients List - Coming Soon!', style: TextStyle(fontSize: 18, color: AppColors.dark)),
      ),
    );
  }
}