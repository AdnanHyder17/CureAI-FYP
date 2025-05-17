// lib/screens/doctor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cached_network_image/cached_network_image.dart';

import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/screens/login_screen.dart';
import 'package:p1/screens/profile_screen.dart'; // Shared profile screen
import 'package:p1/screens/doctor_appointments_screen.dart'; // Your implemented screen
import 'package:p1/screens/doctor_patients_list_screen.dart'; // Placeholder
import 'package:p1/screens/ai_chatbot_screen.dart';
import 'package:p1/screens/individual_chat_screen.dart'; // For navigating from appointment
import 'package:p1/screens/call_screen.dart';
import 'package:p1/services/chat_service.dart'; // For ChatService and call initiation

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0; // 0: Home, 1: Bookings, 2: Patients, 3: Profile
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _doctorNickname;
  String? _profileImageUrl;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DoctorHomeTab(),
      const DoctorAppointmentsScreen(), // Using the one provided previously
      const DoctorPatientsListScreen(), // Placeholder
      const ProfileScreen(), // Shared profile screen
    ];
    WidgetsBinding.instance.addObserver(this);
    _fetchDoctorDetailsForAppBar();
    _updateDoctorOnlinePresence('online', 'available'); // Set online when dashboard is active
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Consider setting to offline if app is fully closing, though lifecycle should handle backgrounding
    // _updateDoctorOnlinePresence('offline', 'unavailable'); // Potentially
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return; // Only act if logged in

    String newStatus = 'offline';
    String newCallStatus = 'unavailable';

    if (state == AppLifecycleState.resumed) {
      newStatus = 'online';
      newCallStatus = 'available';
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) { // hidden is for Flutter 3.13+
      newStatus = 'offline';
      newCallStatus = 'unavailable';
    }
    _updateDoctorOnlinePresence(newStatus, newCallStatus);
  }

  Future<void> _updateDoctorOnlinePresence(String onlineStatus, String callStatusIfOnline) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentReference doctorRef = _firestore.collection('doctors').doc(currentUser.uid);
        DocumentSnapshot doctorSnap = await doctorRef.get();
        String currentCallStatusOnDB = 'unavailable';

        if (doctorSnap.exists && doctorSnap.data() != null) {
          currentCallStatusOnDB = (doctorSnap.data() as Map<String,dynamic>)['callStatus'] ?? 'unavailable';
        }

        String newCallStatusToSet = (onlineStatus == 'online')
            ? (currentCallStatusOnDB == 'on_call' ? 'on_call' : callStatusIfOnline)
            : 'unavailable';

        // Only update if status actually changes to avoid unnecessary writes
        String currentOnlineStatusOnDB = (doctorSnap.data() as Map<String,dynamic>?)?['status'] ?? 'offline';
        if (currentOnlineStatusOnDB != onlineStatus || currentCallStatusOnDB != newCallStatusToSet) {
          await doctorRef.set({
            'status': onlineStatus,
            'callStatus': newCallStatusToSet,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint("Doctor ${currentUser.uid} presence updated to status: $onlineStatus, callStatus: $newCallStatusToSet by dashboard lifecycle.");
        }
      } catch (e) {
        debugPrint("Error updating doctor's online presence from dashboard: $e");
      }
    }
  }


  Future<void> _fetchDoctorDetailsForAppBar() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Fetch from 'users' collection first for nickname and consistent image URL
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _doctorNickname = data['nickname'] as String?;
            _profileImageUrl = data['profileImageUrl'] as String?;
          });
        } else {
          // Fallback to 'doctors' collection if not in 'users' (should ideally be consistent)
          DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
          if (mounted && doctorDoc.exists) {
            final data = doctorDoc.data() as Map<String, dynamic>;
            setState(() {
              _doctorNickname = data['nickname'] as String?; // Ensure 'nickname' exists in doctors doc
              _profileImageUrl = data['profileImageUrl'] as String?;
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching doctor details for dashboard AppBar: $e");
      }
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Logout', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out of CureAI?', style: TextStyle(color: AppColors.dark)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update status before signing out
                final User? currentUser = _auth.currentUser;
                if (currentUser != null) {
                  try {
                    await _firestore.collection('doctors').doc(currentUser.uid).set({
                      'status': 'offline',
                      'callStatus': 'unavailable',
                      'lastStatusUpdate': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    debugPrint("Doctor ${currentUser.uid} status set to offline on logout.");
                  } catch (e) {
                    debugPrint("Error setting doctor offline on logout: $e");
                  }
                }
                await _auth.signOut();
                Navigator.of(dialogContext).pop(true); // Indicate logout confirmed
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Doctor Dashboard';
    if (_currentIndex == 0) {
      appBarTitle = _doctorNickname != null ? 'Dr. $_doctorNickname' : 'Dashboard';
    } else if (_currentIndex == 1) {
      appBarTitle = 'My Appointments'; // Changed from "Bookings"
    } else if (_currentIndex == 2) {
      appBarTitle = 'My Patients';
    } else if (_currentIndex == 3) {
      appBarTitle = 'My Profile';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 20)),
        backgroundColor: AppColors.primary,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _confirmLogout();
              },
              icon: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.8),
                backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                    : null,
                radius: 18,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) && (_doctorNickname != null && _doctorNickname!.isNotEmpty)
                    ? Text(_doctorNickname![0].toUpperCase(), style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))
                    : ((_profileImageUrl == null || _profileImageUrl!.isEmpty) ? const Icon(Icons.person_outline, size: 20, color: AppColors.white) : null),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 10), Text('Logout', style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatbotScreen()));
        },
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        elevation: 4.0,
        shape: const CircleBorder(),
        tooltip: 'AI Health Assistant',
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/logo_icon_white.png', // Ensure this asset exists
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.bubble_chart_outlined, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.white,
        elevation: 8.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildDoctorBottomNavItem(icon: Icons.dashboard_rounded, label: 'Home', index: 0),
              _buildDoctorBottomNavItem(icon: Icons.calendar_month_rounded, label: 'Appointments', index: 1), // Changed from "Bookings"
              const SizedBox(width: 48), // FAB notch space
              _buildDoctorBottomNavItem(icon: Icons.people_alt_rounded, label: 'Patients', index: 2),
              _buildDoctorBottomNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorBottomNavItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.gray, size: 26),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.gray, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// --- DoctorHomeTab (Content for the Home tab of Doctor Dashboard) ---
class DoctorHomeTab extends StatefulWidget {
  const DoctorHomeTab({super.key});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService(); // For initiating calls

  Future<void> _refreshData() async {
    if (mounted) setState(() {});
  }

  String _formatTimeSlotForDisplay(BuildContext context, String? rawTimeSlot) {
    if (rawTimeSlot == null || rawTimeSlot.isEmpty) return 'N/A';
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return rawTimeSlot;
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      return rawTimeSlot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Center(child: Text("Not logged in."));

    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(currentUser.uid),
            const SizedBox(height: 24),
            Text("Today's Appointments", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('appointments')
                  .where('doctorId', isEqualTo: currentUser.uid)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
                  .where('date', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
                  .where('status', whereIn: ['scheduled', 'rescheduled_by_patient', 'active', 'ongoing']) // Only show actionable statuses for today
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 150, child: Center(child: LoadingIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), color: AppColors.white,
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      child: const Column(children: [
                        Icon(Icons.event_note_outlined, color: AppColors.gray, size: 50),
                        SizedBox(height: 16),
                        Text("No appointments scheduled for today.", style: TextStyle(color: AppColors.dark, fontSize: 17, fontWeight: FontWeight.w500)),
                        SizedBox(height: 8),
                        Text("Check 'Appointments' tab for your full schedule.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 14)),
                      ]),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final appointmentDoc = snapshot.data!.docs[index];
                    final appointment = appointmentDoc.data() as Map<String, dynamic>;
                    return _buildTodaysAppointmentCard(context, appointment, appointmentDoc.id);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAppointmentCard(BuildContext context, Map<String, dynamic> appointment, String appointmentId) {
    final String patientName = appointment['patientName'] ?? 'N/A';
    final String patientId = appointment['patientId'] ?? '';
    final DateTime appointmentDateTime = (appointment['date'] as Timestamp).toDate();
    final String timeSlot = _formatTimeSlotForDisplay(context, DateFormat('HH:mm').format(appointmentDateTime)); // Format from DateTime
    final String status = StringExtension((appointment['status'] as String? ?? "Scheduled").replaceAll('_', ' ')).capitalizeFirstLetter();
    final bool isCallActiveOrOngoing = appointment['status'] == 'active' || appointment['status'] == 'ongoing';
    final DateTime currentEndTime = (appointment['currentEndTime'] as Timestamp).toDate();


    final bool canStartCall = (status == 'Scheduled' || status.contains('Rescheduled')) &&
        DateTime.now().isAfter(appointmentDateTime.subtract(const Duration(minutes: 10))) && // Allow starting 10 mins before
        DateTime.now().isBefore(currentEndTime); // Must be before current end time to start/join

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'scheduled': case 'rescheduled by patient': case 'rescheduled by doctor':
      statusColor = AppColors.primary; break;
      case 'active': case 'ongoing':
      statusColor = AppColors.success; break;
      default: statusColor = AppColors.gray;
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppColors.secondary.withOpacity(0.15), radius: 24,
                  child: Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P', style: const TextStyle(fontSize: 20, color: AppColors.secondary, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(patientName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 3),
                Text('Time: $timeSlot', style: TextStyle(color: AppColors.dark.withOpacity(0.75), fontSize: 14)),
              ])),
              Chip(
                label: Text(status, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              )
            ]),
            const SizedBox(height: 12),
            Divider(color: AppColors.gray.withOpacity(0.2), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (patientId.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Chat'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => IndividualChatScreen(receiverId: patientId, receiverName: patientName)));
                    },
                  ),
                const SizedBox(width: 8),
                if (canStartCall || isCallActiveOrOngoing)
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
                      DocumentSnapshot apptDoc = await _firestore.collection('appointments').doc(appointmentId).get();
                      if (!mounted || !apptDoc.exists) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment details not found.")));
                        return;
                      }
                      final currentApptData = apptDoc.data() as Map<String, dynamic>;
                      String callRoomId = currentApptData['callRoomId'] as String? ?? await _chatService.createCallRoom(patientId, 'video');

                      if(canStartCall && !isCallActiveOrOngoing) { // Only update to active if it was previously just scheduled
                        await _firestore.collection('appointments').doc(appointmentId).update({
                          'status': 'active',
                          'callRoomId': callRoomId,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                      }

                      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
                        callRoomId: callRoomId,
                        receiverId: patientId,
                        receiverName: patientName,
                        isCaller: true,
                        callType: 'video',
                        appointmentId: appointmentId,
                        originalAppointmentEndTime: currentApptData['originalEndTime'] as Timestamp,
                        currentAppointmentEndTime: currentApptData['currentEndTime'] as Timestamp,
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

  Widget _buildStatsSection(String doctorId) {
    final DateTime todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  stream: _firestore.collection('appointments')
                      .where('doctorId', isEqualTo: doctorId)
                      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart)) // Appointments from today onwards
                      .where('status', whereIn: ['scheduled', 'rescheduled_by_patient', 'active', 'ongoing'])
                      .snapshots(),
                  title: "Upcoming",
                  icon: Icons.event,
                  color: AppColors.success,
                  valueExtractor: (snapshot) => snapshot.docs.length.toString(),
                ),
                _buildStatItem(
                  stream: _firestore.collection('appointments')
                      .where('doctorId', isEqualTo: doctorId)
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  title: "Completed",
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.secondary,
                  valueExtractor: (snapshot) => snapshot.docs.length.toString(),
                ),
                StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('appointments')
                        .where('doctorId', isEqualTo: doctorId)
                        .where('status', whereIn: ['completed', 'active', 'ongoing', 'scheduled', 'rescheduled_by_patient']) // count distinct patients from all relevant appointments
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return _buildStatItemContent("Patients", "...", Icons.people_alt_rounded, AppColors.primary.withOpacity(0.8));
                      if (snapshot.hasError) return _buildStatItemContent("Patients", "Err", Icons.error_outline_rounded, AppColors.error);

                      Set<String> patientIds = {};
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data != null && data.containsKey('patientId')) {
                            patientIds.add(data['patientId'] as String);
                          }
                        }
                      }
                      return _buildStatItemContent("Patients", patientIds.length.toString(), Icons.people_alt_rounded, AppColors.primary.withOpacity(0.8));
                    }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required Stream<QuerySnapshot> stream,
    required String title,
    required IconData icon,
    required Color color,
    required String Function(QuerySnapshot) valueExtractor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatItemContent(title, "...", icon, color);
        }
        if (snapshot.hasError) {
          debugPrint("Error fetching stat for $title: ${snapshot.error}");
          return _buildStatItemContent(title, "Err", Icons.error_outline_rounded, AppColors.error);
        }
        String value = "0";
        if (snapshot.hasData) {
          value = valueExtractor(snapshot.data!);
        }
        return _buildStatItemContent(title, value, icon, color);
      },
    );
  }

  Widget _buildStatItemContent(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 28, backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 13, color: AppColors.dark.withOpacity(0.7))),
      ],
    );
  }
}

// Helper extension for String capitalization
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    List<String> words = replaceAll('_', ' ').split(' ');
    words = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    return words.join(' ');
  }
}