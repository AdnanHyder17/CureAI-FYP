// lib/screens/doctor_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For patient images

import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/screens/individual_chat_screen.dart';
import 'package:p1/screens/call_screen.dart';
import 'package:p1/services/chat_service.dart'; // For initiating calls

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  late TabController _tabController;

  // Cache for patient profile images
  final Map<String, String?> _patientImageCache = {};


  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndUpdateAppointmentStatus(DocumentSnapshot appointmentDoc) async {
    if (!mounted || _currentUser == null) return;
    Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;
    String currentStatus = data['status'] ?? '';
    Timestamp? currentEndTimeStamp = data['currentEndTime'] as Timestamp?;

    // Only transition from 'scheduled' or 'rescheduled' states automatically
    if ((currentStatus == 'scheduled' ||
        currentStatus == 'rescheduled_by_patient' ||
        currentStatus == 'rescheduled_by_doctor' ||
        currentStatus == 'active' || // Also check active/ongoing if they passed without completion
        currentStatus == 'ongoing') &&
        currentEndTimeStamp != null) {
      DateTime currentEndTime = currentEndTimeStamp.toDate();
      if (DateTime.now().isAfter(currentEndTime)) {
        // If call was active or ongoing and passed end time without explicit 'completed', mark as completed.
        // If it was scheduled and never became active/ongoing, mark as missed.
        bool callUsed = data['videoCallUsed'] as bool? ?? false;
        String newStatus;
        if (currentStatus == 'active' || currentStatus == 'ongoing') {
          newStatus = 'completed'; // Assume if it was active/ongoing and time passed, it's completed
        } else {
          newStatus = callUsed ? 'completed' : 'missed';
        }

        try {
          await _firestore.collection('appointments').doc(appointmentDoc.id).update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint("Doctor's appointment ${appointmentDoc.id} status updated to $newStatus by doctor's client.");
        } catch (e) {
          debugPrint("Failed to update doctor's appointment status for ${appointmentDoc.id}: $e");
        }
      }
    }
  }

  Future<String?> _getPatientProfileImageUrl(String patientId) async {
    if (_patientImageCache.containsKey(patientId)) {
      return _patientImageCache[patientId];
    }
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(patientId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final imageUrl = (userDoc.data() as Map<String, dynamic>)['profileImageUrl'] as String?;
        if (mounted) {
          setState(() {
            _patientImageCache[patientId] = imageUrl;
          });
        }
        return imageUrl;
      }
    } catch (e) {
      debugPrint("Error fetching patient image for $patientId: $e");
    }
    if (mounted) { // Cache null if not found to prevent re-fetching constantly
      setState(() {
        _patientImageCache[patientId] = null;
      });
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text("Please log in."));
    }
    return Column(
      children: [
        Material(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.white,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.light.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList(isUpcoming: true),
              _buildAppointmentsList(isUpcoming: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList({required bool isUpcoming}) {
    Query query;
    if (isUpcoming) {
      query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _currentUser!.uid)
          .where('status', whereIn: ['scheduled', 'rescheduled_by_patient', 'rescheduled_by_doctor', 'active', 'ongoing'])
          .where('currentEndTime', isGreaterThanOrEqualTo: Timestamp.now()) // Use currentEndTime for upcoming
          .orderBy('currentEndTime')
          .orderBy('date'); // Secondary sort by actual start time
    } else {
      query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _currentUser!.uid)
          .where('status', whereIn: ['completed', 'missed', 'cancelled_by_patient', 'cancelled_by_doctor'])
          .orderBy('date', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          debugPrint("Error fetching doctor's appointments: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isUpcoming ? Icons.event_note_outlined : Icons.history_rounded, size: 60, color: AppColors.gray.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(
                    isUpcoming ? 'No upcoming appointments.' : 'No past appointments found.',
                    style: const TextStyle(fontSize: 17, color: AppColors.dark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        // Automatically update status for appointments
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              _checkAndUpdateAppointmentStatus(doc);
            }
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final appointmentData = doc.data() as Map<String, dynamic>;
            return _buildDoctorAppointmentCard(context, appointmentData, doc.id, isUpcoming);
          },
        );
      },
    );
  }

  Widget _buildDoctorAppointmentCard(BuildContext context, Map<String, dynamic> appointment, String appointmentId, bool isUpcoming) {
    final String patientName = appointment['patientName'] ?? 'N/A';
    final String patientId = appointment['patientId'] ?? '';
    final DateTime appointmentDateTime = (appointment['date'] as Timestamp).toDate();
    final String timeSlot = TimeOfDay(hour: appointmentDateTime.hour, minute: appointmentDateTime.minute).format(context);
    final String formattedDate = DateFormat('EEE, MMM d, yyyy').format(appointmentDateTime);
    final String status = (appointment['status'] as String? ?? "Scheduled").replaceAll('_', ' ').capitalizeFirstLetter();
    final int durationMinutes = appointment['durationMinutes'] as int? ?? 15;
    final DateTime originalEndTime = (appointment['originalEndTime'] as Timestamp).toDate();
    final DateTime currentEndTime = (appointment['currentEndTime'] as Timestamp).toDate();


    Color statusColor;
    IconData statusIcon;
    switch (appointment['status']?.toLowerCase()) {
      case 'scheduled':
      case 'rescheduled_by_patient':
      case 'rescheduled_by_doctor':
        statusColor = AppColors.primary;
        statusIcon = Icons.alarm_on_rounded;
        break;
      case 'active':
      case 'ongoing':
        statusColor = AppColors.success;
        statusIcon = Icons.phone_in_talk_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success.withOpacity(0.8);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled_by_patient':
      case 'cancelled_by_doctor':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'missed':
        statusColor = AppColors.warning;
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        statusColor = AppColors.gray;
        statusIcon = Icons.help_outline_rounded;
    }

    final bool canStartCall = isUpcoming &&
        (status == 'Scheduled' || status.contains('Rescheduled')) &&
        DateTime.now().isAfter(appointmentDateTime.subtract(const Duration(minutes: 5))) && // Can start 5 mins before
        DateTime.now().isBefore(currentEndTime); // Must be before current end time

    final bool isCallActiveOrOngoing = status == 'Active' || status == 'Ongoing';


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<String?>(
                    future: _getPatientProfileImageUrl(patientId), // Fetch image
                    builder: (context, snapshot) {
                      String? imageUrl = snapshot.data;
                      if (snapshot.connectionState == ConnectionState.waiting && !_patientImageCache.containsKey(patientId)) {
                        return const CircleAvatar(radius: 26, backgroundColor: AppColors.light, child: LoadingIndicator(size: 15));
                      }
                      return CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P', style: const TextStyle(fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold))
                            : null,
                      );
                    }
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      const SizedBox(height: 2),
                      Text('$formattedDate at $timeSlot', style: TextStyle(fontSize: 13.5, color: AppColors.dark.withOpacity(0.75))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 5),
                      Text(status, style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.gray.withOpacity(0.2), height: 1.0),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (patientId.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Message'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => IndividualChatScreen(
                        receiverId: patientId,
                        receiverName: patientName,
                        receiverImageUrl: _patientImageCache[patientId], // Use cached image
                      )));
                    },
                  ),
                const SizedBox(width: 8),
                if (isUpcoming && (canStartCall || isCallActiveOrOngoing))
                  ElevatedButton.icon(
                    icon: Icon(isCallActiveOrOngoing ? Icons.phone_in_talk_rounded : Icons.video_call_rounded, size: 18),
                    label: Text(isCallActiveOrOngoing ? 'Join Call' : 'Start Call'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isCallActiveOrOngoing ? AppColors.success : AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                    ),
                    onPressed: () async {
                      // Fetch latest appointment details before navigating to CallScreen
                      DocumentSnapshot apptDoc = await _firestore.collection('appointments').doc(appointmentId).get();
                      if (!mounted || !apptDoc.exists) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment details not found.")));
                        return;
                      }
                      final currentApptData = apptDoc.data() as Map<String, dynamic>;
                      final String callRoomId = currentApptData['callRoomId'] as String? ?? await ChatService().createCallRoom(patientId, 'video');

                      // Update status to 'active' if doctor starts it
                      if(canStartCall && !isCallActiveOrOngoing) {
                        await _firestore.collection('appointments').doc(appointmentId).update({
                          'status': 'active',
                          'callRoomId': callRoomId, // Ensure callRoomId is saved
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      }

                      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
                        callRoomId: callRoomId,
                        receiverId: patientId,
                        receiverName: patientName,
                        isCaller: true, // Doctor initiating/joining from their side
                        callType: 'video',
                        appointmentId: appointmentId,
                        originalAppointmentEndTime: (currentApptData['originalEndTime'] as Timestamp),
                        currentAppointmentEndTime: (currentApptData['currentEndTime'] as Timestamp),
                      )));
                    },
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Helper extension (if not already globally available)
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    List<String> words = replaceAll('_', ' ').split(' ');
    words = words.map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '').toList();
    return words.join(' ');
  }
}