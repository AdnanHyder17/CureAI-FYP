// lib/screens/doctor_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:p1/theme.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar can be removed if DoctorDashboardScreen handles it
      // appBar: AppBar(title: Text('My Appointments'), backgroundColor: AppColors.primary),
      body: Center(
        // TODO: Implement Doctor's appointment management view (Calendar/List)
        // Allow accept/reschedule/cancel
        child: Text('Doctor Appointments Management - Coming Soon!', style: TextStyle(fontSize: 18, color: AppColors.dark)),
      ),
    );
  }
}