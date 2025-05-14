// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:p1/theme.dart';
import 'package:p1/screens/individual_chat_screen.dart'; // Add this
import 'package:p1/screens/call_screen.dart'; // Add this
import 'package:p1/services/chat_service.dart'; // Add this
import 'package:permission_handler/permission_handler.dart'; // For permissions

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const DoctorDetailsScreen({super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ChatService _chatService = ChatService();
  String _selectedTab = 'About';
  String _selectedDay = '';
  String _nickname = 'Doctor';
  bool _isLoading = true;

  DateTime _selectedBookingDate = DateTime.now(); // For booking dialog
  String? _selectedBookingTimeSlot; // e.g., "10:00"
  List<String> _availableTimeSlotsForBooking = [];
  List<String> _bookedTimeSlotsForSelectedDate = [];
  bool _isLoadingSlots = false;

  bool _canCurrentlyCommunicate = false;
  StreamSubscription? _appointmentStreamSubscriptionForCommunication;

  // Update permission request utility
  Future<bool> _requestCallPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isPermanentlyDenied || statuses[Permission.microphone]!.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted;
  }


  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Your existing method
    _setupCommunicationEligibilityListener(); // New method
  }

  void _setupCommunicationEligibilityListener() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Cancel any existing subscription
    _appointmentStreamSubscriptionForCommunication?.cancel();

    // This stream should find the *specific active or next upcoming* appointment
    // that would grant communication privileges.
    _appointmentStreamSubscriptionForCommunication = FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser.uid)
        .where('doctorId', isEqualTo: widget.doctorId)
    // MODIFIED LINE: Add your active appointment statuses here
        .where('status', whereIn: ['scheduled', 'rescheduled', 'active', 'ongoing'])
    // Potentially order by date to get the most relevant one
        .orderBy('date', descending: false) // Get upcoming ones first
        .snapshots() // Listen to real-time changes
        .listen((snapshot) {
      bool eligible = false;
      if (snapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        for (var doc in snapshot.docs) { // Iterate through appointments
          final appointmentData = doc.data() as Map<String, dynamic>;
          final DateTime appointmentStartTime = (appointmentData['date'] as Timestamp).toDate();
          final int duration = appointmentData['durationMinutes'] as int? ?? 15;
          final DateTime appointmentEndTime = (appointmentData['currentEndTime'] as Timestamp?)?.toDate() ??
              appointmentStartTime.add(Duration(minutes: duration));

          // More precise eligibility: communication allowed from 1 min before start up to 15 mins after actual end
          DateTime communicationWindowStart = appointmentStartTime.subtract(const Duration(minutes: 1));
          DateTime communicationWindowEnd = appointmentEndTime.add(const Duration(minutes: 15)); // For post-call chat

          if (now.isAfter(communicationWindowStart) && now.isBefore(communicationWindowEnd)) {
            eligible = true;
            break; // Found an eligible appointment
          }
        }
      }
      if (mounted && _canCurrentlyCommunicate != eligible) {
        setState(() {
          _canCurrentlyCommunicate = eligible;
          debugPrint("Communication eligibility updated to: $_canCurrentlyCommunicate with status check for ['scheduled', 'rescheduled', 'active', 'ongoing']");
        });
      }
    });
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('nickname')) {
          setState(() {
            _nickname = userData['nickname'];
          });
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.doctorData['status'] == 'online';

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildAppBar(isOnline),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDoctorInfo(),
                _buildActionButtons(),
                _buildTabButtons(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBookAppointmentButton(),
    );
  }

  // Custom app bar with doctor image
  Widget _buildAppBar(bool isOnline) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back),
          color: AppColors.dark,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.light,
              child: widget.doctorData['profileImageUrl'] != null
                  ? CachedNetworkImage(
                imageUrl: widget.doctorData['profileImageUrl'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                errorWidget: (context, url, error) => _buildProfilePlaceholder(),
              )
                  : _buildProfilePlaceholder(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Doctor info section
  Widget _buildDoctorInfo() {
    final double rating = (widget.doctorData['rating'] ?? 0).toDouble();
    final String specialty = widget.doctorData['specialty'] ?? 'Specialist';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $_nickname',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.doctorData['consultationFee']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Fees',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.work_history,
                iconColor: AppColors.secondary,
                value: '${widget.doctorData['yearsOfExperience'] ?? 0}+',
                label: 'Experience',
              ),
              _buildInfoItem(
                icon: Icons.people,
                iconColor: AppColors.primary,
                value: '',
                label: 'Patients',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Info item with icon, value and label
  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }

  // Action buttons for message and video call
  Widget _buildActionButtons() {
    // Use the state variable _canCurrentlyCommunicate directly
    final bool isCommunicationAllowed = _canCurrentlyCommunicate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.message,
              label: 'Message',
              // Use the state variable here
              color: isCommunicationAllowed ? AppColors.primary : Colors.grey,
              onTap: isCommunicationAllowed ? _handleMessage : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can message during your scheduled appointment window.')));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.videocam,
              label: 'Video Call',
              // Use the state variable here
              color: isCommunicationAllowed ? AppColors.secondary : Colors.grey,
              onTap: isCommunicationAllowed ? () => _handleVideoCall('video') : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can call during your scheduled appointment window.')));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessage() {
    // Navigate to IndividualChatScreen
    // The doctorData likely has 'nickname' which can be used as receiverName.
    // Ensure widget.doctorData['nickname'] exists and is correct.
    // If not, you might need to fetch it from 'users' collection using widget.doctorId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualChatScreen(
          receiverId: widget.doctorId,
          receiverName: widget.doctorData['nickname'] ?? 'Doctor', // Use nickname from doctorData
        ),
      ),
    );
  }

  // Modify _handleVideoCall - this now initiates a direct video call
  Future<void> _handleVideoCall(String callType) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to make a call.")));
      return;
    }

    // 1. Request Permissions
    bool permissionsGranted = await _requestCallPermissions();
    if (!permissionsGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and Microphone permissions are required for video calls.'))
        );
      }
      return;
    }

    // --- START: Fetch LATEST Doctor Status from Firestore ---
    String latestDoctorStatus = 'offline';
    String latestDoctorCallStatus = 'unavailable'; // Default to unavailable
    String doctorNickname = widget.doctorData['nickname'] ?? 'Doctor'; // Use initial nickname as fallback

    try {
      DocumentSnapshot doctorProfileDoc = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      DocumentSnapshot doctorUserDoc = await FirebaseFirestore.instance.collection('users').doc(widget.doctorId).get(); // For nickname if needed

      if (doctorProfileDoc.exists) {
        final profileData = doctorProfileDoc.data() as Map<String, dynamic>;
        latestDoctorStatus = profileData['status'] ?? 'offline';
        latestDoctorCallStatus = profileData['callStatus'] ?? 'available';
        // Update nickname from profileData if it's more specific or preferred
        doctorNickname = profileData['nickname'] ?? doctorNickname;
      } else if (doctorUserDoc.exists) {
        // Fallback to user document if doctor profile specific doc doesn't exist
        // (though 'status' and 'callStatus' are usually in 'doctors' collection)
        doctorNickname = (doctorUserDoc.data() as Map<String,dynamic>)['nickname'] ?? doctorNickname;
        // Assume offline/available if no specific doctor profile
        latestDoctorStatus = (doctorUserDoc.data() as Map<String,dynamic>)['status'] ?? 'offline'; // users collection might also have a general status
      }
    } catch (e) {
      debugPrint("Error fetching latest doctor status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify doctor availability. Please try again.')),
        );
      }
      return;
    }
    // --- END: Fetch LATEST Doctor Status ---

    // 2. Check Doctor's LATEST Online and Call Status
    if (latestDoctorStatus != 'online' || latestDoctorCallStatus == 'on_call' || latestDoctorCallStatus == 'busy') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dr. $doctorNickname is currently unavailable or busy.')),
        );
      }
      return;
    }

    // 3. Fetch relevant ACTIVE appointment details for this patient and doctor
    DocumentSnapshot? relevantAppointmentDoc;
    String? fetchedAppointmentId;
    Timestamp? fetchedOriginalEndTime;
    Timestamp? fetchedCurrentEndTime;
    final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance; // Use a local instance

    try {
      // Patient (currentUser) is calling the doctor (widget.doctorId)
      QuerySnapshot apptSnapshot = await _firestoreInstance.collection('appointments')
          .where('patientId', isEqualTo: currentUser.uid)
          .where('doctorId', isEqualTo: widget.doctorId)
      // Ensure status check here allows for ongoing/active appointments if your system uses them
          .where('status', whereIn: ['scheduled', 'rescheduled', 'active', 'ongoing'])
          .orderBy('date', descending: true)
          .get();

      if (apptSnapshot.docs.isNotEmpty) {
        for (var doc in apptSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp apptStartTimestamp = data['date'] as Timestamp;
          final Timestamp? apptCurrentEndTimestamp = data['currentEndTime'] as Timestamp?;

          if (apptCurrentEndTimestamp != null) {
            final DateTime apptStart = apptStartTimestamp.toDate();
            final DateTime apptCurrentEnd = apptCurrentEndTimestamp.toDate();
            final DateTime now = DateTime.now();

            // Window for patient to initiate call (e.g., 1 min before start to end of current window)
            if (now.isAfter(apptStart.subtract(const Duration(minutes: 1))) && now.isBefore(apptCurrentEnd)) {
              relevantAppointmentDoc = doc;
              break;
            }
          }
        }
      }

      if (relevantAppointmentDoc != null && relevantAppointmentDoc.exists) {
        final appointmentData = relevantAppointmentDoc.data() as Map<String, dynamic>;
        fetchedAppointmentId = relevantAppointmentDoc.id;
        fetchedOriginalEndTime = appointmentData['originalEndTime'] as Timestamp?;
        fetchedCurrentEndTime = appointmentData['currentEndTime'] as Timestamp?;

        if (fetchedOriginalEndTime == null || fetchedCurrentEndTime == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected appointment details are incomplete. Call cannot proceed.")));
          return;
        }
      } else {
        // This check should ideally be redundant if the call button is already enabled by _canCurrentlyCommunicate,
        // which uses a similar time window. However, having it here provides a server-side data check.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can call the doctor during your scheduled appointment window.'))
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Error fetching appointment details for call in DoctorDetailsScreen: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching appointment details: ${e.toString()}")));
      return;
    }

    // 4. Proceed to Create Call Room and Navigate
    try {
      // Use the potentially updated doctorNickname
      String callRoomId = await _chatService.createCallRoom(widget.doctorId, callType);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              callRoomId: callRoomId,
              receiverId: widget.doctorId,
              receiverName: doctorNickname, // Use fetched/updated nickname
              isCaller: true,
              callType: callType,
              appointmentId: fetchedAppointmentId!,
              originalAppointmentEndTime: fetchedOriginalEndTime!,
              currentAppointmentEndTime: fetchedCurrentEndTime!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting $callType call: $e')),
        );
      }
    }
  }

  // Action button widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isWide = true,
    VoidCallback? onTap, // Make onTap nullable
  }) {
    return GestureDetector(
      onTap: onTap, // Pass the nullable onTap directly
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: isWide ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            if (isWide) SizedBox(width: 8),
            if (isWide)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tab buttons for About, Experience
  Widget _buildTabButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabButton('About'),
          _buildTabButton('Experience'),
        ],
      ),
    );
  }

  // Individual tab button
  Widget _buildTabButton(String tabName) {
    final bool isSelected = _selectedTab == tabName;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabName;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              tabName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.gray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Content for selected tab
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'About':
        return _buildAboutContent();
      case 'Experience':
        return _buildExperienceContent();
      default:
        return _buildAboutContent();
    }
  }

  // About tab content
  Widget _buildAboutContent() {
    final String about = widget.doctorData['about'] ?? 'No information provided';
    final List<String> languages = List<String>.from(widget.doctorData['languages'] ?? []);

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Doctor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            about,
            style: TextStyle(
              color: AppColors.dark.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Languages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((language) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray.withOpacity(0.3)),
                ),
                child: Text(
                  language,
                  style: TextStyle(
                    color: AppColors.dark,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Working Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildAvailabilityCalendar(),
        ],
      ),
    );
  }

  // Calendar widget for doctor availability
  Widget _buildAvailabilityCalendar() {
    Map<String, dynamic> availabilityFromDoctorData = widget.doctorData['availability'] ?? {};
    Map<String, List<Map<String, String>>> availability = {};

    availabilityFromDoctorData.forEach((day, rangesDynamic) {
      if (rangesDynamic is List) {
        availability[day] = rangesDynamic.map((rangeMapDynamic) {
          if (rangeMapDynamic is Map) {
            final start = rangeMapDynamic['start'] as String?;
            final end = rangeMapDynamic['end'] as String?;
            if (start != null && end != null) {
              return {'start': start, 'end': end};
            }
          }
          return null;
        }).where((range) => range != null).cast<Map<String, String>>().toList();
      }
    });

    List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select a day to view timings:",
          style: TextStyle(color: AppColors.dark.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((day) {
            final shortDay = day.substring(0, 3).toUpperCase();
            final bool isAvailableOnThisDay = availability.containsKey(day) && availability[day]!.isNotEmpty;
            final bool isSelected = _selectedDay == day;

            return Expanded(
              child: GestureDetector(
                onTap: isAvailableOnThisDay ? () {
                  setState(() { _selectedDay = isSelected ? '' : day; });
                } : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isAvailableOnThisDay ? AppColors.light : AppColors.gray.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailableOnThisDay ? (isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3)) : AppColors.gray.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4, offset: Offset(0,2))] : [],
                  ),
                  child: Center(
                    child: Text(shortDay, style: TextStyle(
                      color: isSelected ? AppColors.white : (isAvailableOnThisDay ? AppColors.primary : AppColors.gray),
                      fontWeight: isAvailableOnThisDay ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedDay.isNotEmpty && availability.containsKey(_selectedDay) && availability[_selectedDay]!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Timings for $_selectedDay:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 10),
                ...availability[_selectedDay]!.map<Widget>((range) { // Iterate through ranges
                  final String startTime = _aformatTimeSlot(range['start'] ?? 'N/A');
                  final String endTime = _aformatTimeSlot(range['end'] ?? 'N/A');
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: Offset(0,1))]
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_filled_outlined, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 10),
                        Text('$startTime - $endTime', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w500, fontSize: 15)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  // Add this helper function to check if a doctor is available on a given day
  bool _isDoctorAvailableOnDay(DateTime day) {
    final String dayOfWeek = _getDayOfWeek(day.weekday);
    final availability = widget.doctorData['availability'] as Map<String, dynamic>?;
    if (availability != null && availability.containsKey(dayOfWeek)) {
      final dayRanges = availability[dayOfWeek] as List<dynamic>?;
      return dayRanges != null && dayRanges.isNotEmpty;
    }
    return false;
  }

  // Experience tab content
  Widget _buildExperienceContent() {
    final String qualifications = widget.doctorData['qualifications'] ?? 'Not specified';
    final String institutions = widget.doctorData['affiliatedInstitutions'] ?? 'Not specified';
    final String licenseNumber = widget.doctorData['licenseNumber'] ?? 'Not specified';
    final int experience = widget.doctorData['yearsOfExperience'] ?? 0;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExperienceItem(
            title: 'Education & Qualifications',
            icon: Icons.school,
            content: qualifications,
          ),
          _buildExperienceItem(
            title: 'Work Experience',
            icon: Icons.work,
            content: '$experience years of clinical experience',
          ),
          _buildExperienceItem(
            title: 'Affiliated Hospitals',
            icon: Icons.local_hospital,
            content: institutions,
          ),
          _buildExperienceItem(
            title: 'License Information',
            icon: Icons.badge,
            content: 'License #$licenseNumber',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // Experience item with icon and content
  Widget _buildExperienceItem({
    required String title,
    required IconData icon,
    required String content,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: AppColors.dark.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for profile image
  Widget _buildProfilePlaceholder() {
    return Container(
      color: AppColors.light,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: AppColors.gray,
            ),
            SizedBox(height: 8),
            Text(
              'No Profile Photo',
              style: TextStyle(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Book appointment button
  Widget _buildBookAppointmentButton() {

    final currentUser = FirebaseAuth.instance.currentUser;
    final isDoctorViewingOwnProfile = currentUser?.uid == widget.doctorId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isDoctorViewingOwnProfile
              ? null
              : () => _showAppointmentBookingDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ).copyWith(
            backgroundColor: MaterialStateProperty.all(
              isDoctorViewingOwnProfile ? Colors.grey : AppColors.primary,
            ),
          ),
          child: Text(
            isDoctorViewingOwnProfile
                ? 'Cannot Book Own Appointment'
                : 'Book Appointment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentBookingDialog() {
    _selectedBookingDate = DateTime.now();
    // Ensure initial date is today or in the future, and find first available day
    DateTime today = DateTime.now();
    DateTime firstPossibleBookingDay = DateTime(today.year, today.month, today.day);
    if (DateTime.now().hour >= 23) { // If too late today, start from tomorrow
      firstPossibleBookingDay = firstPossibleBookingDay.add(const Duration(days:1));
    }
    _selectedBookingDate = firstPossibleBookingDay;


    DateTime initialPickerDate = _selectedBookingDate;
    int daysToScan = 0;
    while (!_isDoctorAvailableOnDay(initialPickerDate) && daysToScan < 60) {
      initialPickerDate = initialPickerDate.add(const Duration(days: 1));
      daysToScan++;
    }
    // If no available day found within 60 days, initialPickerDate will be 60 days from start
    // The CalendarDatePicker will still respect selectableDayPredicate
    _selectedBookingDate = initialPickerDate;


    _selectedBookingTimeSlot = null;
    _availableTimeSlotsForBooking = [];
    _bookedTimeSlotsForSelectedDate = [];
    // _isLoadingSlots is managed by updateSlotsForDate and _fetchBookedSlotsForDate

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // Use a local flag for initial load within the modal's StatefulBuilder
        bool _isModalFirstLoad = true;

        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            // This function now correctly manages _isLoadingSlots
            void updateSlotsForDate(DateTime date) async {
              modalSetState(() {
                _isLoadingSlots = true;
                _availableTimeSlotsForBooking = [];
                _selectedBookingTimeSlot = null;
              });

              final String dayOfWeek = _getDayOfWeek(date.weekday);
              List<Map<String, String>> doctorDayAvailability = [];

              if (widget.doctorData['availability'] != null &&
                  widget.doctorData['availability'][dayOfWeek] != null) {
                try {
                  doctorDayAvailability = List<Map<String, String>>.from(
                      (widget.doctorData['availability'][dayOfWeek] as List<dynamic>).map(
                              (item) => Map<String, String>.from(item as Map<dynamic,dynamic>)));
                } catch (e) {
                  debugPrint("Error parsing doctor availability for $dayOfWeek: $e");
                  doctorDayAvailability = [];
                }
              }

              List<String> generatedSlots = [];
              if (doctorDayAvailability.isNotEmpty) {
                for (var range in doctorDayAvailability) {
                  final startTimeParts = range['start']?.split(':');
                  final endTimeParts = range['end']?.split(':');

                  if (startTimeParts != null && startTimeParts.length == 2 &&
                      endTimeParts != null && endTimeParts.length == 2) {

                    TimeOfDay startTime = TimeOfDay(hour: int.parse(startTimeParts[0]), minute: int.parse(startTimeParts[1]));
                    TimeOfDay endTime = TimeOfDay(hour: int.parse(endTimeParts[0]), minute: int.parse(endTimeParts[1]));

                    DateTime currentSlotTime = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                    DateTime rangedEndTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

                    // Loop to generate 15-minute slots
                    // The condition currentSlotTime.isBefore(rangedEndTime) ensures that
                    // a slot starting at rangedEndTime is not included.
                    // E.g., if range is 10:00-11:00, slots are 10:00, 10:15, 10:30, 10:45.
                    while(currentSlotTime.isBefore(rangedEndTime)) {
                      bool isSlotInPast = date.isSameDate(DateTime.now()) &&
                          currentSlotTime.isBefore(DateTime.now().add(const Duration(minutes: 5))); // Add a small buffer
                      if (!isSlotInPast) {
                        generatedSlots.add(
                            '${currentSlotTime.hour.toString().padLeft(2, '0')}:${currentSlotTime.minute.toString().padLeft(2, '0')}'
                        );
                      }
                      currentSlotTime = currentSlotTime.add(const Duration(minutes: 15));
                    }
                  }
                }
              }

              // Fetch booked slots and then update UI
              await _fetchBookedSlotsForDate(date, modalSetStateCallback: modalSetState);

              // Now update available slots and ensure loading is false
              modalSetState(() {
                _availableTimeSlotsForBooking = generatedSlots;
                _isLoadingSlots = false; // Crucial: set loading to false AFTER all async ops
              });
            }

            if (_isModalFirstLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ctx.mounted) {
                  updateSlotsForDate(_selectedBookingDate);
                  modalSetState(() { // Use modalSetState for changes within the modal
                    _isModalFirstLoad = false;
                  });
                }
              });
            }

            return Container(
              // ... (rest of your Container and Column structure from the Canvas) ...
              // Ensure CalendarDatePicker uses _selectedBookingDate and _isDoctorAvailableOnDay
              // Ensure GridView.builder uses _availableTimeSlotsForBooking, _bookedTimeSlotsForSelectedDate, _isLoadingSlots
              // and _isDoctorAvailableOnDay(_selectedBookingDate) for conditional display
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Book Appointment', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: Icon(Icons.close, color: AppColors.white), onPressed: () => Navigator.pop(modalContext))
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: CalendarDatePicker(
                              initialDate: _selectedBookingDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                              selectableDayPredicate: _isDoctorAvailableOnDay,
                              onDateChanged: (date) {
                                modalSetState(() {
                                  _selectedBookingDate = date;
                                });
                                updateSlotsForDate(date);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Select Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                          const SizedBox(height: 12),
                          if (_isLoadingSlots)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ))
                          else if (!_isDoctorAvailableOnDay(_selectedBookingDate))
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('Doctor is not available on ${DateFormat('EEE, MMM d').format(_selectedBookingDate)}.', style: TextStyle(color: AppColors.gray, fontSize: 15))),
                            )
                          else if (_availableTimeSlotsForBooking.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text('No available slots for ${DateFormat('EEE, MMM d').format(_selectedBookingDate)}.', style: TextStyle(color: AppColors.gray, fontSize: 15))),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.8,
                                ),
                                itemCount: _availableTimeSlotsForBooking.length,
                                itemBuilder: (context, index) {
                                  final timeSlot = _availableTimeSlotsForBooking[index];
                                  final isBooked = _bookedTimeSlotsForSelectedDate.contains(timeSlot);
                                  final isSelected = timeSlot == _selectedBookingTimeSlot;

                                  return GestureDetector(
                                    onTap: isBooked ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('This time slot is already booked.'), backgroundColor: AppColors.warning),
                                      );
                                    } : () {
                                      modalSetState(() {
                                        _selectedBookingTimeSlot = timeSlot;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isBooked ? AppColors.gray.withOpacity(0.2)
                                            : isSelected ? AppColors.secondary : AppColors.light.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : (isBooked ? AppColors.gray.withOpacity(0.4) : AppColors.primary.withOpacity(0.4)),
                                          width: isSelected ? 2 : 1.2,
                                        ),
                                        boxShadow: isSelected ? [
                                          BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 5, offset: Offset(0,2))
                                        ] : [
                                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, offset: Offset(0,1))
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _aformatTimeSlot(timeSlot),
                                          style: TextStyle(
                                            color: isBooked ? AppColors.dark.withOpacity(0.4)
                                                : isSelected ? AppColors.white : AppColors.primary,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 13,
                                            decoration: isBooked ? TextDecoration.lineThrough : TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: (_selectedBookingTimeSlot == null || !_isDoctorAvailableOnDay(_selectedBookingDate))
                          ? null
                          : () {
                        Navigator.pop(modalContext);
                        _confirmAppointment(_selectedBookingDate, _selectedBookingTimeSlot!);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.gray.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      child: const Text('Confirm Appointment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper to fetch booked slots for a specific date
  Future<void> _fetchBookedSlotsForDate(DateTime date, {StateSetter? modalSetStateCallback, bool forUpdateSlots = false}) async {
    if (!forUpdateSlots) { // Only set loading true if it's not part of the updateSlotsForDate sequence where it's already true
      if (modalSetStateCallback != null) modalSetStateCallback(() => _isLoadingSlots = true);
      else if (mounted) setState(() => _isLoadingSlots = true);
    }

    final DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      List<String> bookedSlots = snapshot.docs.map((doc) => doc['timeSlot'] as String).toList();

      if (modalSetStateCallback != null) {
        modalSetStateCallback(() {
          _bookedTimeSlotsForSelectedDate = bookedSlots;
          // _isLoadingSlots is set to false in updateSlotsForDate after this await completes
          // or if forUpdateSlots is true, it means updateSlotsForDate will handle it.
          // However, to be safe, especially if this is called independently:
          _isLoadingSlots = false;
        });
      } else if (mounted) {
        setState(() {
          _bookedTimeSlotsForSelectedDate = bookedSlots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching booked slots: $e");
      if (modalSetStateCallback != null) {
        modalSetStateCallback(() => _isLoadingSlots = false);
      } else if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

// Helper function to get day of week
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

// Format time slot for display
  String _aformatTimeSlot(String rawTimeSlot) {
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot;

      int hour = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      String minuteStr = minutes.toString().padLeft(2, '0'); // Ensure two-digit minutes
      String period = hour >= 12 ? 'PM' : 'AM';

      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour); // Convert 24-hour to 12-hour format

      return '$hour:$minuteStr $period'; // Return properly formatted time
    } catch (e) {
      return rawTimeSlot; // Return original if formatting fails
    }
  }

// Show confirmation dialog and save appointment
  void _confirmAppointment(DateTime selectedDate, String timeSlot) async {
    // Get current user ID

    final String? patientId = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return;
    }

    // Format date for display
    final String formattedDate =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $formattedDate',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Time: ${_aformatTimeSlot(timeSlot)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Doctor: ${widget.doctorData['nickname'] ?? 'Dr. ' + _nickname}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Fee: ${widget.doctorData['consultationFee'] ?? 0}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(color: AppColors.gray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              _bookAppointment(selectedDate, timeSlot, patientId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }



  DateTime _combineDateAndTime(DateTime date, String timeSlot) {
    final timeParts = timeSlot.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }




  Future<bool> _isTimeSlotAvailable(DateTime appointmentDateTime, String timeSlot) async {
    try {
      // Create the query to check for existing appointments
      final query = FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId) // Check for the specific doctor
          .where('date', isEqualTo: Timestamp.fromDate(appointmentDateTime)) // Check for the specific date and time
          .limit(1); // Limit to 1 result for efficiency

      // Execute the query
      final snapshot = await query.get();

      // If no documents are returned, the time slot is available
      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking time slot availability: $e');
      return false; // Assume slot is unavailable if there's an error
    }
  }




// Separate method to handle the actual booking process
  Future<void> _bookAppointment(DateTime selectedDate, String timeSlot, String patientId) async {

    // Show loading dialog
    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: const [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 20),
                Text('Booking appointment...',
                  style: TextStyle(color: AppColors.dark),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Combine date and time into a single DateTime object
      final appointmentDateTime = _combineDateAndTime(selectedDate, timeSlot);

      // Check if the time slot is available
      final isAvailable = await _isTimeSlotAvailable(appointmentDateTime, timeSlot);
      if (!isAvailable) {
        Navigator.of(dialogContext, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This time slot is no longer available')),
        );
        return;
      }

      final int appointmentDurationMinutes = 15; // Or make this configurable, e.g., based on doctor's settings or service type
      final DateTime appointmentStartTime = _combineDateAndTime(selectedDate, timeSlot);
      final DateTime appointmentEndTime = appointmentStartTime.add(Duration(minutes: appointmentDurationMinutes));

      // Create appointment data
      final Map<String, dynamic> appointmentData = {
        'patientId': patientId,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['nickname']?.isNotEmpty == true ? widget.doctorData['nickname'] : 'Doctor',
        'specialty': widget.doctorData['specialty']?.isNotEmpty == true ? widget.doctorData['specialty'] : 'Consultation',
        'patientName': (await FirebaseFirestore.instance.collection('users').doc(patientId).get()).data()?['nickname'] ?? 'Patient',
        'date': Timestamp.fromDate(appointmentStartTime), // This is the start time
        'timeSlot': timeSlot, // Keep for display if needed, but 'date' is canonical start
        'durationMinutes': appointmentDurationMinutes, // **** NEW FIELD ****
        'originalEndTime': Timestamp.fromDate(appointmentEndTime), // **** NEW FIELD **** (calculated from start + duration)
        'currentEndTime': Timestamp.fromDate(appointmentEndTime), // **** NEW FIELD **** (initially same as original, can be extended)
        'status': 'scheduled',
        'consultationFee': widget.doctorData['consultationFee'] ?? 0,
        'createdAt': Timestamp.now(),
        'videoCallUsed': false,
        'doctorsNote': '',
        'timesExtended': 0, // **** NEW FIELD **** (to track extensions)
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      Navigator.of(dialogContext, rootNavigator: true).pop(); // Close loading dialog

      // Make sure patientName and doctorName are available
      String patientName = "You"; // Or fetch current user's nickname
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) patientName = (userDoc.data() as Map<String,dynamic>)['nickname'] ?? "You";
      }

      _showSuccessDialog();

    } catch (e) {
      Navigator.of(dialogContext, rootNavigator: true).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: $e')),
      );
    }



  }

// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Text('Success!'),
          ],
        ),
        content: const Text(
          'Your appointment has been successfully booked. You can view your appointments in the appointments section.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }
}

// Add this extension outside the class if you don't have it
extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem(this.name, this.icon, this.color);
}
