// lib/screens/patient_detail_screen_for_doctor.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current doctor for chat
import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/screens/individual_chat_screen.dart'; // For chat button

class PatientDetailScreenForDoctor extends StatefulWidget {
  final String patientId;
  final String patientName; // Passed for quick display
  final String? patientImageUrl; // Passed for quick display

  const PatientDetailScreenForDoctor({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
  });

  @override
  State<PatientDetailScreenForDoctor> createState() => _PatientDetailScreenForDoctorState();
}

class _PatientDetailScreenForDoctorState extends State<PatientDetailScreenForDoctor> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData; // From 'users' collection
  Map<String, dynamic>? _patientData; // From 'patients' collection (health details)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientFullDetails();
  }

  Future<void> _fetchPatientFullDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint("[PatientDetailScreenForDoctor] Fetching details for patient ID: ${widget.patientId}");
      // Fetch from 'users' collection
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.patientId).get();
      if (mounted && userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        debugPrint("[PatientDetailScreenForDoctor] User data: $_userData");
      } else {
        debugPrint("[PatientDetailScreenForDoctor] No document found in 'users' for ID: ${widget.patientId}");
      }

      // Fetch from 'patients' collection (health specific details)
      DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(widget.patientId).get();
      if (mounted && patientDoc.exists) {
        _patientData = patientDoc.data() as Map<String, dynamic>;
        debugPrint("[PatientDetailScreenForDoctor] Patient specific data: $_patientData");
      } else {
        debugPrint("[PatientDetailScreenForDoctor] No document found in 'patients' for ID: ${widget.patientId}");
      }

      if (!mounted) return;

      if (_userData == null && _patientData == null) {
        _errorMessage = "Could not load patient details.";
      }

    } catch (e) {
      debugPrint("[PatientDetailScreenForDoctor] Error fetching patient details: $e");
      if (mounted) _errorMessage = "An error occurred while fetching details.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String? value, {bool isSummary = false}) {
    final String displayValue = (value == null || value.isEmpty) ? "N/A" : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isSummary ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: AppColors.dark.withOpacity(0.7), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.dark, height: isSummary ? 1.4 : 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final User? currentDoctor = FirebaseAuth.instance.currentUser;
    String displayName = _userData?['nickname'] ?? widget.patientName;
    String? displayImageUrl = _userData?['profileImageUrl'] ?? widget.patientImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      backgroundColor: AppColors.light,
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: "Loading patient details..."))
          : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 16))))
          : _userData == null && _patientData == null // If both are null after loading (and no error message)
          ? const Center(child: Text("Patient details are not available.", style: TextStyle(fontSize: 16, color: AppColors.gray)))
          : _buildPatientDetailsContent(displayName, displayImageUrl),
      floatingActionButton: (_isLoading || _errorMessage != null || currentDoctor == null)
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualChatScreen(
                receiverId: widget.patientId,
                receiverName: displayName, // Use the most up-to-date name
                receiverImageUrl: displayImageUrl,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text("Chat with Patient"),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildPatientDetailsContent(String name, String? imageUrl) {
    // Basic Info
    final String email = _userData?['email'] ?? 'N/A';
    final String country = _userData?['country'] ?? 'N/A';
    final String age = (_patientData?['basicInfo']?['age'] ?? _patientData?['age'] ?? 'N/A').toString();
    final String gender = _patientData?['basicInfo']?['gender'] ?? _patientData?['gender'] ?? 'N/A';

    // Health Profile Summaries (assuming simplified structure from patient's profile screen)
    String medicalSummary = "Not specified";
    if (_patientData?['healthProfile'] != null) {
      final hp = _patientData!['healthProfile'] as Map<String, dynamic>;
      medicalSummary = [
        (hp['chronicConditionsSelected'] as List<dynamic>? ?? []).join(', '),
        hp['chronicConditionsOther'],
        (hp['allergiesDetails'] ?? ''),
        (hp['surgicalHistoryDetails'] ?? ''),
        (hp['currentMedicationsDetails'] ?? '')
      ].where((s) => s != null && s.isNotEmpty).join('; \n') ;
      if (medicalSummary.isEmpty) medicalSummary = "No specific conditions or allergies listed.";
    } else if (_patientData?['medicalSummary'] != null) { // Fallback to direct summary field
      medicalSummary = _patientData!['medicalSummary'];
    }


    String lifestyleSummary = "Not specified";
    if (_patientData?['lifestyleHabits'] != null) {
      final lh = _patientData!['lifestyleHabits'] as Map<String, dynamic>;
      lifestyleSummary = [
        lh['smokingStatus'] != null ? "Smoking: ${lh['smokingStatus']}" : null,
        lh['alcoholConsumption'] != null ? "Alcohol: ${lh['alcoholConsumption']}" : null,
        lh['physicalActivityLevel'] != null ? "Activity: ${lh['physicalActivityLevel']}" : null,
        lh['sleepDuration'] != null ? "Sleep: ${lh['sleepDuration']}" : null,
        lh['stressLevel'] != null ? "Stress: ${lh['stressLevel']}" : null,
      ].where((s) => s != null && s.isNotEmpty).join('; \n');
      if (lifestyleSummary.isEmpty) lifestyleSummary = "Lifestyle habits not detailed.";
    } else if (_patientData?['lifestyleSummary'] != null) { // Fallback
      lifestyleSummary = _patientData!['lifestyleSummary'];
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(imageUrl)
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: const TextStyle(fontSize: 40, color: AppColors.primary))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Center(child: Text("Patient ID: ${widget.patientId}", style: TextStyle(fontSize: 13, color: AppColors.gray))),

          _buildSectionTitle("Contact & Basic Info"),
          _buildDetailItem(Icons.email_outlined, "Email", email),
          _buildDetailItem(Icons.flag_outlined, "Country", country),
          _buildDetailItem(Icons.cake_outlined, "Age", age),
          _buildDetailItem(Icons.wc_outlined, "Gender", gender),

          if(_patientData != null) ...[ // Only show health sections if patient-specific data is loaded
            _buildSectionTitle("Health Summary"),
            _buildDetailItem(Icons.medical_information_outlined, "Medical Conditions & History", medicalSummary, isSummary: true),

            _buildSectionTitle("Lifestyle Summary"),
            _buildDetailItem(Icons.spa_outlined, "Habits (Smoking, Alcohol, Activity, Sleep, Stress)", lifestyleSummary, isSummary: true),
          ],

          const SizedBox(height: 70), // Space for FAB
        ],
      ),
    );
  }
}