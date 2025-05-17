// lib/screens/doctor_patients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/screens/individual_chat_screen.dart'; // For chat button on detail screen

// Placeholder for the new detail screen we will create
import 'patient_detail_screen_for_doctor.dart';

class DoctorPatientsListScreen extends StatefulWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  State<DoctorPatientsListScreen> createState() => _DoctorPatientsListScreenState();
}

class _DoctorPatientsListScreenState extends State<DoctorPatientsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  bool _isLoading = true;
  List<Map<String, dynamic>> _distinctPatients = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchDistinctPatients();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "User not logged in.";
      });
    }
  }

  Future<void> _fetchDistinctPatients() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("[DoctorPatientsListScreen] Fetching appointments for doctor: ${_currentUser!.uid}");
      QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _currentUser!.uid)
      // Optionally filter by status to only include patients from 'completed' or 'active' appointments
      // .where('status', whereIn: ['completed', 'active', 'ongoing', 'scheduled', 'rescheduled_by_patient', 'rescheduled_by_doctor'])
          .get();

      if (!mounted) return;

      if (appointmentsSnapshot.docs.isEmpty) {
        debugPrint("[DoctorPatientsListScreen] No appointments found for this doctor.");
        setState(() {
          _distinctPatients = [];
          _isLoading = false;
        });
        return;
      }

      Map<String, Map<String, dynamic>> patientMap = {};

      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final patientId = data['patientId'] as String?;
        final patientNameFromAppointment = data['patientName'] as String?; // Use name from appointment as fallback

        if (patientId != null && !patientMap.containsKey(patientId)) {
          patientMap[patientId] = {
            'id': patientId,
            'name': patientNameFromAppointment ?? 'Patient', // Default if not in appointment
            'profileImageUrl': null, // Will be fetched next
          };
        }
      }

      debugPrint("[DoctorPatientsListScreen] Found ${patientMap.length} distinct patient IDs from appointments.");

      if (patientMap.isEmpty) {
        setState(() {
          _distinctPatients = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> patientsWithDetails = [];
      for (String patientId in patientMap.keys) {
        try {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(patientId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            patientsWithDetails.add({
              'id': patientId,
              'name': userData['nickname'] ?? patientMap[patientId]!['name'], // Prefer nickname from users collection
              'profileImageUrl': userData['profileImageUrl'] as String?,
              // Add any other basic details needed for the list item itself
            });
          } else {
            // If user doc doesn't exist, use the info from appointment (already in patientMap)
            patientsWithDetails.add(patientMap[patientId]!);
            debugPrint("[DoctorPatientsListScreen] User document not found for patientId: $patientId. Using name from appointment.");
          }
        } catch (e) {
          debugPrint("[DoctorPatientsListScreen] Error fetching user details for patientId $patientId: $e");
          // Add patient with data from appointment even if user details fetch fails
          patientsWithDetails.add(patientMap[patientId]!);
        }
      }
      // Sort patients by name
      patientsWithDetails.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));


      if (mounted) {
        setState(() {
          _distinctPatients = patientsWithDetails;
          _isLoading = false;
        });
        debugPrint("[DoctorPatientsListScreen] Successfully fetched ${patientsWithDetails.length} distinct patient details.");
      }
    } catch (e) {
      debugPrint("[DoctorPatientsListScreen] Error fetching distinct patients: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load patients list. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen is usually part of DoctorDashboardScreen, which provides an AppBar.
    // If used standalone, an AppBar might be needed here.
    return Scaffold(
      backgroundColor: AppColors.light,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator(message: "Loading patients..."));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }
    if (_distinctPatients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 70, color: AppColors.gray.withOpacity(0.8)),
              const SizedBox(height: 16),
              const Text(
                'No Patients Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Your list of consulted patients will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.dark.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDistinctPatients,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        itemCount: _distinctPatients.length,
        itemBuilder: (context, index) {
          final patient = _distinctPatients[index];
          final String patientName = patient['name'] ?? 'Unknown Patient';
          final String? patientImageUrl = patient['profileImageUrl'] as String?;
          final String patientId = patient['id'] as String;

          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondary.withOpacity(0.15),
                backgroundImage: (patientImageUrl != null && patientImageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(patientImageUrl)
                    : null,
                child: (patientImageUrl == null || patientImageUrl.isEmpty)
                    ? Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              title: Text(
                patientName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5, color: AppColors.dark),
              ),
              subtitle: Text(
                'Patient ID: $patientId', // Or other relevant info like last consultation date
                style: TextStyle(fontSize: 13, color: AppColors.dark.withOpacity(0.6)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.gray),
              onTap: () {
                debugPrint("[DoctorPatientsListScreen] Tapped on patient: $patientName (ID: $patientId)");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailScreenForDoctor(
                      patientId: patientId,
                      patientName: patientName,
                      patientImageUrl: patientImageUrl,
                    ),
                  ),
                );
              },
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 2),
      ),
    );
  }
}