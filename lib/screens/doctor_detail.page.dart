// lib/screens/doctor_detail.page.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/screens/individual_chat_screen.dart';
import 'package:p1/screens/call_screen.dart';
import 'package:p1/services/chat_service.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData; // Initial data passed from list screen

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  late TabController _tabController;
  bool _isLoadingDetails = true;
  Map<String, dynamic> _currentDoctorData = {};
  String _doctorNickname = '';

  // Communication eligibility
  bool _canCurrentlyCommunicate = false;
  bool _isWithinStrictCallWindow = false; // For video call button specifically
  StreamSubscription? _appointmentCommunicationSubscription;
  String? _activeAppointmentIdForCall;
  Timestamp? _activeAppointmentOriginalEndTime;
  Timestamp? _activeAppointmentCurrentEndTime;
  int _activeAppointmentDurationMinutes = 15; // Default

  // Booking state
  DateTime _selectedBookingDate = DateTime.now();
  String? _selectedBookingTimeSlot;
  List<String> _availableTimeSlotsForBooking = [];
  List<String> _bookedTimeSlotsForSelectedDate = [];
  bool _isLoadingBookingSlots = false;
  String _selectedDayForAvailabilityView = DateFormat('EEEE').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    debugPrint("[DoctorDetailsScreen] initState for Dr. ID: ${widget.doctorId}");
    _tabController = TabController(length: 2, vsync: this);
    _currentDoctorData = widget.doctorData;
    _doctorNickname = _currentDoctorData['nickname'] ?? 'Doctor';
    _fetchFullDoctorDetails();
    _setupCommunicationEligibilityListener();
    _initializeBookingDate();
  }

  void _initializeBookingDate() {
    DateTime today = DateTime.now();
    DateTime firstPossibleBookingDay = DateTime(today.year, today.month, today.day);
    if (DateTime.now().hour >= 22) { // If it's late (e.g., after 10 PM), default to next day
      firstPossibleBookingDay = firstPossibleBookingDay.add(const Duration(days:1));
    }
    _selectedBookingDate = firstPossibleBookingDay;
    int daysToScan = 0;
    // Ensure _currentDoctorData['availability'] is checked safely
    while (!_isDoctorAvailableOnDay(_selectedBookingDate) && daysToScan < 60) {
      _selectedBookingDate = _selectedBookingDate.add(const Duration(days: 1));
      daysToScan++;
    }
    debugPrint("[DoctorDetailsScreen] Initialized booking date to: $_selectedBookingDate");
  }


  @override
  void dispose() {
    debugPrint("[DoctorDetailsScreen] dispose for Dr. ID: ${widget.doctorId}");
    _tabController.dispose();
    _appointmentCommunicationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchFullDoctorDetails() async {
    if (!mounted) return;
    debugPrint("[DoctorDetailsScreen] Fetching full doctor details for Dr. ID: ${widget.doctorId}");
    setState(() => _isLoadingDetails = true);
    try {
      DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(widget.doctorId).get();
      if (mounted && doctorDoc.exists) {
        _currentDoctorData = doctorDoc.data() as Map<String, dynamic>;
        _doctorNickname = _currentDoctorData['nickname'] ?? 'Doctor';
        debugPrint("[DoctorDetailsScreen] Loaded data from 'doctors' collection: $_currentDoctorData");
      }
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.doctorId).get();
      if (mounted && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _doctorNickname = _currentDoctorData['nickname'] ?? userData['nickname'] ?? 'Doctor';
        if (_currentDoctorData['profileImageUrl'] == null && userData['profileImageUrl'] != null) {
          _currentDoctorData['profileImageUrl'] = userData['profileImageUrl'];
        }
        debugPrint("[DoctorDetailsScreen] Loaded/merged data from 'users' collection. Nickname: $_doctorNickname");
      }
    } catch (e) {
      debugPrint("[DoctorDetailsScreen] Error fetching full doctor details: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load latest doctor details."), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  void _setupCommunicationEligibilityListener() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("[DoctorDetailsScreen] No current user for communication eligibility.");
      return;
    }
    debugPrint("[DoctorDetailsScreen] Setting up communication eligibility listener for patient: ${currentUser.uid} and doctor: ${widget.doctorId}");

    _appointmentCommunicationSubscription?.cancel();
    _appointmentCommunicationSubscription = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser.uid)
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', whereIn: ['scheduled', 'rescheduled_by_doctor', 'rescheduled_by_patient', 'active', 'ongoing'])
        .orderBy('date', descending: false)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      debugPrint("[DoctorDetailsScreen Listener] Snapshot received. Docs count: ${snapshot.docs.length}");
      bool newEligibleForCommunication = false;
      bool newWithinStrictCallTime = false;
      String? newActiveAppointmentId;
      Timestamp? newActiveAppointmentOriginalEndTime, newActiveAppointmentCurrentEndTime;
      int newActiveAppointmentDurationMinutes = 15;

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final appointmentData = doc.data() as Map<String, dynamic>;
        debugPrint("[DoctorDetailsScreen Listener] Found appointment: ${doc.id}, status: ${appointmentData['status']}, data: $appointmentData");

        final DateTime appointmentStartTime = (appointmentData['date'] as Timestamp).toDate();
        newActiveAppointmentDurationMinutes = appointmentData['durationMinutes'] as int? ?? 15;

        final DateTime appointmentOriginalEndTimeFromData = (appointmentData['originalEndTime'] as Timestamp?)?.toDate() ??
            appointmentStartTime.add(Duration(minutes: newActiveAppointmentDurationMinutes));

        final DateTime appointmentCurrentEndTime = (appointmentData['currentEndTime'] as Timestamp?)?.toDate() ??
            appointmentOriginalEndTimeFromData;

        final DateTime now = DateTime.now();
        // final DateTime nowUTC = DateTime.now().toUtc(); // For comparing with pure UTC if needed

        debugPrint("--- [DoctorDetailsScreen Listener] Time Check ---");
        debugPrint("Now (Local): $now");
        // debugPrint("Now (UTC): $nowUTC");
        debugPrint("Appt Start (Local from Firestore): $appointmentStartTime");
        debugPrint("Appt Current End (Local from Firestore): $appointmentCurrentEndTime");
        debugPrint("Appt Original End (Local from Firestore): $appointmentOriginalEndTimeFromData");


        DateTime communicationWindowStart = appointmentStartTime.subtract(const Duration(minutes: 5));
        DateTime communicationWindowEnd = appointmentCurrentEndTime.add(const Duration(minutes: 15));
        debugPrint("Communication Window: $communicationWindowStart TO $communicationWindowEnd");

        bool isAfterCommStart = now.isAfter(communicationWindowStart);
        bool isBeforeCommEnd = now.isBefore(communicationWindowEnd);
        newEligibleForCommunication = isAfterCommStart && isBeforeCommEnd;
        debugPrint("Message eligibility: isAfterCommStart ($isAfterCommStart) && isBeforeCommEnd ($isBeforeCommEnd) -> $newEligibleForCommunication");

        bool isAfterStrictStart = (now.isAtSameMomentAs(appointmentStartTime) || now.isAfter(appointmentStartTime));
        bool isBeforeStrictEnd = now.isBefore(appointmentCurrentEndTime);
        newWithinStrictCallTime = isAfterStrictStart && isBeforeStrictEnd;
        debugPrint("Video eligibility: isAfterStrictStart ($isAfterStrictStart) && isBeforeStrictEnd ($isBeforeStrictEnd) -> $newWithinStrictCallTime");

        if (newEligibleForCommunication || newWithinStrictCallTime) {
          newActiveAppointmentId = doc.id;
          newActiveAppointmentOriginalEndTime = appointmentData['originalEndTime'] as Timestamp? ?? Timestamp.fromDate(appointmentOriginalEndTimeFromData);
          newActiveAppointmentCurrentEndTime = appointmentData['currentEndTime'] as Timestamp? ?? Timestamp.fromDate(appointmentCurrentEndTime);
        }
      } else {
        debugPrint("[DoctorDetailsScreen Listener] No active/upcoming appointments found for this doctor by this patient meeting criteria.");
      }

      if (mounted) {
        if (_canCurrentlyCommunicate != newEligibleForCommunication ||
            _isWithinStrictCallWindow != newWithinStrictCallTime ||
            _activeAppointmentIdForCall != newActiveAppointmentId) {
          debugPrint("[DoctorDetailsScreen Listener] Updating state: Comm: $newEligibleForCommunication, VideoStrict: $newWithinStrictCallTime, ApptID: $newActiveAppointmentId");
          setState(() {
            _canCurrentlyCommunicate = newEligibleForCommunication;
            _isWithinStrictCallWindow = newWithinStrictCallTime;
            _activeAppointmentIdForCall = newActiveAppointmentId;
            _activeAppointmentOriginalEndTime = newActiveAppointmentOriginalEndTime;
            _activeAppointmentCurrentEndTime = newActiveAppointmentCurrentEndTime;
            _activeAppointmentDurationMinutes = newActiveAppointmentDurationMinutes;
          });
        } else {
          debugPrint("[DoctorDetailsScreen Listener] State not updated as flags and apptId haven't changed from: Comm: $_canCurrentlyCommunicate, VideoStrict: $_isWithinStrictCallWindow, ApptID: $_activeAppointmentIdForCall");
        }
      }
    }, onError: (error) {
      debugPrint("[DoctorDetailsScreen Listener] Error: $error");
      if (mounted) {
        setState(() {
          _canCurrentlyCommunicate = false;
          _isWithinStrictCallWindow = false;
          _activeAppointmentIdForCall = null;
        });
      }
    });
  }

  Future<bool> _requestCallPermissions() async {
    debugPrint("[DoctorDetailsScreen] Requesting call permissions...");
    Map<Permission, PermissionStatus> statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isPermanentlyDenied || statuses[Permission.microphone]!.isPermanentlyDenied) {
      debugPrint("[DoctorDetailsScreen] Call permissions permanently denied.");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissions permanently denied. Please enable them in app settings.'), duration: Duration(seconds: 3))
        );
        await Future.delayed(const Duration(milliseconds: 500));
        openAppSettings();
      }
      return false;
    }
    if (!statuses[Permission.camera]!.isGranted || !statuses[Permission.microphone]!.isGranted) {
      debugPrint("[DoctorDetailsScreen] Camera or Mic permission not granted. Camera: ${statuses[Permission.camera]}, Mic: ${statuses[Permission.microphone]}");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera and Microphone permissions are required for video calls.')));
      return false;
    }
    debugPrint("[DoctorDetailsScreen] Call permissions granted.");
    return true;
  }

  void _handleMessage() {
    debugPrint("[DoctorDetailsScreen] _handleMessage called. _canCurrentlyCommunicate: $_canCurrentlyCommunicate");
    if (!_canCurrentlyCommunicate) { // This check is redundant if button is disabled, but good for safety
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging is available during your scheduled appointment window.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => IndividualChatScreen(
      receiverId: widget.doctorId,
      receiverName: _doctorNickname,
      receiverImageUrl: _currentDoctorData['profileImageUrl'] as String?,
    )));
  }

  Future<void> _handleVideoCall() async {
    debugPrint("[DoctorDetailsScreen] _handleVideoCall called. _canCurrentlyCommunicate: $_canCurrentlyCommunicate, _isWithinStrictCallWindow: $_isWithinStrictCallWindow, ApptID: $_activeAppointmentIdForCall");

    // These checks are technically covered by button enablement, but good for direct calls
    if (!_canCurrentlyCommunicate || !_isWithinStrictCallWindow) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video call is only available during the exact appointment time.')));
      return;
    }
    if (_activeAppointmentIdForCall == null || _activeAppointmentOriginalEndTime == null || _activeAppointmentCurrentEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video call is available during your scheduled appointment window but appointment details are missing.')));
      return;
    }


    bool permissionsGranted = await _requestCallPermissions();
    if (!permissionsGranted) return;

    if(!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: LoadingIndicator(message: "Preparing call...")));

    try {
      DocumentSnapshot doctorProfileDoc = await _firestore.collection('doctors').doc(widget.doctorId).get();
      if (!mounted) { Navigator.pop(context); return; }
      if (!doctorProfileDoc.exists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor details not found.')));
        debugPrint("[DoctorDetailsScreen] Doctor profile not found for ID: ${widget.doctorId}");
        return;
      }
      final doctorStatusData = doctorProfileDoc.data() as Map<String, dynamic>;
      final String latestDoctorStatus = doctorStatusData['status'] ?? 'offline';
      final String latestDoctorCallStatus = doctorStatusData['callStatus'] ?? 'unavailable';
      debugPrint("[DoctorDetailsScreen] Doctor Firestore Status: $latestDoctorStatus, CallStatus: $latestDoctorCallStatus");


      if (latestDoctorStatus != 'online' || (latestDoctorCallStatus != 'available' && latestDoctorCallStatus != 'ringing')) { // Allow if ringing to join
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dr. $_doctorNickname is currently $latestDoctorStatus and call status is $latestDoctorCallStatus.')));
        return;
      }

      DocumentSnapshot apptDoc = await _firestore.collection('appointments').doc(_activeAppointmentIdForCall!).get();
      if (!mounted) { Navigator.pop(context); return; }
      if (!apptDoc.exists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment details missing.')));
        debugPrint("[DoctorDetailsScreen] Active Appointment ID $_activeAppointmentIdForCall details missing.");
        return;
      }
      final apptData = apptDoc.data() as Map<String, dynamic>;
      String callRoomId = apptData['callRoomId'] as String? ?? await _chatService.createCallRoom(widget.doctorId, 'video');
      debugPrint("[DoctorDetailsScreen] Using CallRoomID: $callRoomId for appointment $_activeAppointmentIdForCall");


      if (apptData['status'] == 'scheduled' || apptData['status'] == 'rescheduled_by_doctor' || apptData['status'] == 'rescheduled_by_patient') {
        await _firestore.collection('appointments').doc(_activeAppointmentIdForCall!).update({
          'status': 'active', // Patient is initiating the active state
          'callRoomId': callRoomId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("[DoctorDetailsScreen] Updated appointment $_activeAppointmentIdForCall status to 'active'.");
      }
      Navigator.pop(context);

      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
        callRoomId: callRoomId,
        receiverId: widget.doctorId,
        receiverName: _doctorNickname,
        isCaller: true, // Patient is always the caller from this screen
        callType: 'video',
        appointmentId: _activeAppointmentIdForCall!,
        originalAppointmentEndTime: _activeAppointmentOriginalEndTime!,
        currentAppointmentEndTime: _activeAppointmentCurrentEndTime!,
      )));
    } catch (e) {
      if(mounted) Navigator.pop(context);
      debugPrint("[DoctorDetailsScreen] Error handling video call: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting video call: ${e.toString()}'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails && _currentDoctorData.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Loading..."), backgroundColor: AppColors.primary, elevation: 0), body: const Center(child: LoadingIndicator(message: "Loading doctor details...")));
    }

    final String? imageUrl = _currentDoctorData['profileImageUrl'] as String?;
    final String specialty = _currentDoctorData['specialty'] ?? 'Specialist';
    final double rating = (_currentDoctorData['rating'] ?? 0.0).toDouble();
    final int reviews = (_currentDoctorData['totalReviews'] ?? 0).toInt();
    final int experience = (_currentDoctorData['yearsOfExperience'] ?? 0).toInt();
    final String fee = (_currentDoctorData['consultationFee']?.toStringAsFixed(0) ?? 'N/A');
    final bool isCurrentUserDoctor = _auth.currentUser?.uid == widget.doctorId;

    return Scaffold(
      backgroundColor: AppColors.light,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false, pinned: true, stretch: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.white),
            elevation: 2.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 72),
              title: Text(
                _doctorNickname,
                style: const TextStyle(color: AppColors.white, fontSize: 22.0, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(0,1))]),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              background: Hero(
                tag: 'doctor_image_${widget.doctorId}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.primary.withOpacity(0.3), child: const Center(child: LoadingIndicator(color: AppColors.white, size: 30))),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary.withOpacity(0.5),
                        child: Icon(Icons.person_rounded, size: 120, color: AppColors.white.withOpacity(0.6)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(specialty, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.star_rate_rounded, color: Colors.amber.shade700, size: 22),
                    const SizedBox(width: 5),
                    Text('${rating.toStringAsFixed(1)} ($reviews Reviews)', style: TextStyle(fontSize: 16, color: AppColors.dark.withOpacity(0.9))),
                    const SizedBox(width: 16),
                    Icon(Icons.medical_information_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 5),
                    Text('$experience+ Years Exp.', style: TextStyle(fontSize: 16, color: AppColors.dark.withOpacity(0.9))),
                  ]),
                  const SizedBox(height: 12),
                  Text('PKR $fee / Session', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 24),
                  if (!isCurrentUserDoctor) _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                ],
              ),
            ),
          ),
          SliverFillRemaining( // Use SliverFillRemaining for TabBarView
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildAvailabilityAndExperienceTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCurrentUserDoctor ? null : _buildBookAppointmentButton(),
    );
  }

  Widget _buildActionButtons() {
    // Debug print for button states
    debugPrint("[DoctorDetailsScreen _buildActionButtons] _canCurrentlyCommunicate: $_canCurrentlyCommunicate, _isWithinStrictCallWindow: $_isWithinStrictCallWindow");
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: const Text('Message'),
            onPressed: _canCurrentlyCommunicate ? _handleMessage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canCurrentlyCommunicate ? AppColors.secondary : AppColors.gray.withOpacity(0.3),
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray.withOpacity(0.2),
              disabledForegroundColor: AppColors.gray.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.video_call_rounded, size: 20),
            label: const Text('Video Call'),
            onPressed: _canCurrentlyCommunicate && _isWithinStrictCallWindow ? _handleVideoCall : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canCurrentlyCommunicate && _isWithinStrictCallWindow ? AppColors.primary : AppColors.gray.withOpacity(0.3),
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray.withOpacity(0.2),
              disabledForegroundColor: AppColors.gray.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppColors.gray.withOpacity(0.2))),
      elevation: 0.5,
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(child: Text('About Doctor', textAlign: TextAlign.center)),
          Tab(child: Text('Availability', textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final String about = _currentDoctorData['about'] ?? 'No detailed information provided by the doctor.';
    final List<String> languages = List<String>.from(_currentDoctorData['languages'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Dr. $_doctorNickname', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 12),
          Text(about, style: TextStyle(fontSize: 15.5, color: AppColors.dark.withOpacity(0.8), height: 1.55)),
          const SizedBox(height: 24),
          Text('Languages Spoken', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 10),
          if (languages.isEmpty) Text('Not specified.', style: TextStyle(color: AppColors.dark.withOpacity(0.7), fontStyle: FontStyle.italic))
          else Wrap(
            spacing: 8.0, runSpacing: 8.0,
            children: languages.map((lang) => Chip(
              label: Text(lang, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500)),
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.secondary.withOpacity(0.3))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityAndExperienceTab() {
    final String qualifications = _currentDoctorData['qualifications'] ?? 'Not specified';
    final String institutions = _currentDoctorData['affiliatedInstitutions'] ?? 'Not specified';
    final String licenseNumber = _currentDoctorData['licenseNumber'] ?? 'Not specified';

    Map<String, List<Map<String, String>>> availability = {};
    (_currentDoctorData['availability'] as Map<String,dynamic>? ?? {}).forEach((day, rangesDynamic) {
      if (rangesDynamic is List) {
        availability[day] = rangesDynamic.map((rangeMapDynamic) {
          if (rangeMapDynamic is Map) {
            return {'start': rangeMapDynamic['start'] as String? ?? '', 'end': rangeMapDynamic['end'] as String? ?? ''};
          }
          return {'start': '', 'end': ''};
        }).where((range) => range['start']!.isNotEmpty && range['end']!.isNotEmpty).toList();
      }
    });
    final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work Experience & Qualifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 16),
          _buildExperienceItem(Icons.school_rounded, 'Qualifications', qualifications),
          _buildExperienceItem(Icons.local_hospital_rounded, 'Affiliated Institutions', institutions.isNotEmpty ? institutions : 'Not specified'),
          _buildExperienceItem(Icons.badge_rounded, 'License Number', licenseNumber),
          const SizedBox(height: 28),
          Text('Weekly Availability', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekdays.length,
              itemBuilder: (context, index) {
                final day = weekdays[index];
                final isSelected = _selectedDayForAvailabilityView == day;
                final isAvailableOnThisDay = availability.containsKey(day) && availability[day]!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: ChoiceChip(
                    label: Text(day.substring(0,3).toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDayForAvailabilityView = day);
                    },
                    backgroundColor: AppColors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? AppColors.white : (isAvailableOnThisDay ? AppColors.primary : AppColors.gray)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.3))),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (availability.containsKey(_selectedDayForAvailabilityView) && availability[_selectedDayForAvailabilityView]!.isNotEmpty)
            Column(
              children: availability[_selectedDayForAvailabilityView]!.map((range) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: AppColors.primary.withOpacity(0.05),
                  child: ListTile(
                    leading: const Icon(Icons.access_time_filled_rounded, color: AppColors.secondary, size: 22),
                    title: Text('${_formatTimeSlotDisplay(range['start']!)} - ${_formatTimeSlotDisplay(range['end']!)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.dark)),
                    dense: true,
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12),
              decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('Dr. $_doctorNickname is not available on $_selectedDayForAvailabilityView.', style: TextStyle(color: AppColors.gray, fontStyle: FontStyle.italic, fontSize: 15))),
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.secondary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const SizedBox(height: 3),
          Text(content, style: TextStyle(fontSize: 14.5, color: AppColors.dark.withOpacity(0.75), height: 1.4)),
        ])),
      ]),
    );
  }

  String _formatTimeSlotDisplay(String rawTimeSlot) {
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return rawTimeSlot;
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      // return timeOfDay.format(context); // This would require context if not available in this scope.
      String period = timeOfDay.period == DayPeriod.am ? "AM" : "PM";
      int displayHour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod; // Converts 0 to 12 for 12 AM
      return "$displayHour:${timeOfDay.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      debugPrint("[DoctorDetailsScreen] Error formatting time slot '$rawTimeSlot': $e");
      return rawTimeSlot;
    }
  }

  Widget _buildBookAppointmentButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12), // Adjusted for safe area
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, -3))],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.calendar_month_rounded, size: 20),
        label: const Text('Book Appointment'),
        onPressed: () => _showAppointmentBookingDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  bool _isDoctorAvailableOnDay(DateTime day) {
    final String dayOfWeek = DateFormat('EEEE').format(day);
    final availabilityMap = _currentDoctorData['availability'] as Map<String, dynamic>?;
    if (availabilityMap != null && availabilityMap.containsKey(dayOfWeek)) {
      final dayRanges = availabilityMap[dayOfWeek] as List<dynamic>?;
      return dayRanges != null && dayRanges.isNotEmpty;
    }
    return false;
  }

  Future<void> _fetchBookedSlotsForDate(DateTime date, StateSetter modalSetState) async {
    if(!mounted) return;
    modalSetState(() => _isLoadingBookingSlots = true);
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    debugPrint("[DoctorDetailsScreen _fetchBookedSlotsForDate] Fetching for $date");
    try {
      final snapshot = await _firestore.collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['scheduled', 'rescheduled_by_doctor', 'rescheduled_by_patient', 'active', 'ongoing'])
          .get();
      if(mounted) {
        modalSetState(() {
          _bookedTimeSlotsForSelectedDate = snapshot.docs.map((doc) => doc['timeSlot'] as String).toList();
          debugPrint("[DoctorDetailsScreen _fetchBookedSlotsForDate] Booked slots for $date: $_bookedTimeSlotsForSelectedDate");
        });
      }
    } catch (e) {
      debugPrint("[DoctorDetailsScreen _fetchBookedSlotsForDate] Error: $e");
    } finally {
      if(mounted) modalSetState(() => _isLoadingBookingSlots = false);
    }
  }

  void _generateAvailableTimeSlots(DateTime date, StateSetter modalSetState) {
    if(!mounted) return;
    modalSetState(() => _isLoadingBookingSlots = true);
    _availableTimeSlotsForBooking.clear();
    _selectedBookingTimeSlot = null;
    debugPrint("[DoctorDetailsScreen _generateAvailableTimeSlots] Generating for date: $date");

    final String dayOfWeek = DateFormat('EEEE').format(date);
    final availabilityMap = _currentDoctorData['availability'] as Map<String, dynamic>?;
    final List<dynamic>? dayRanges = availabilityMap?[dayOfWeek] as List<dynamic>?;
    final int appointmentDuration = _currentDoctorData['appointmentDurationMinutes'] as int? ?? 15;

    if (dayRanges != null) {
      for (var range in dayRanges) {
        if (range is Map) {
          final startStr = range['start'] as String?;
          final endStr = range['end'] as String?;
          if (startStr != null && endStr != null) {
            try {
              TimeOfDay startTime = TimeOfDay(hour: int.parse(startStr.split(':')[0]), minute: int.parse(startStr.split(':')[1]));
              TimeOfDay endTime = TimeOfDay(hour: int.parse(endStr.split(':')[0]), minute: int.parse(endStr.split(':')[1]));
              DateTime currentSlotStart = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
              DateTime rangeEndDateTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

              while (currentSlotStart.add(Duration(minutes: appointmentDuration)).isBefore(rangeEndDateTime) ||
                  currentSlotStart.add(Duration(minutes: appointmentDuration)).isAtSameMomentAs(rangeEndDateTime)) {
                bool isSlotInPast = date.isSameDateAs(DateTime.now()) && currentSlotStart.isBefore(DateTime.now().add(const Duration(minutes: 10)));
                if (!isSlotInPast) {
                  _availableTimeSlotsForBooking.add(DateFormat('HH:mm').format(currentSlotStart));
                }
                currentSlotStart = currentSlotStart.add(const Duration(minutes: 15)); // Assuming slots generated every 15 mins. Change if duration is different for generation step.
              }
            } catch (e) { debugPrint("[DoctorDetailsScreen _generateAvailableTimeSlots] Error parsing time range: $e"); }
          }
        }
      }
    }
    debugPrint("[DoctorDetailsScreen _generateAvailableTimeSlots] Generated raw slots: $_availableTimeSlotsForBooking");
    _fetchBookedSlotsForDate(date, modalSetState);
  }

  void _showAppointmentBookingDialog() {
    _initializeBookingDate(); // Reset to a sensible default or first available day
    _selectedBookingTimeSlot = null;
    _availableTimeSlotsForBooking = [];
    _bookedTimeSlotsForSelectedDate = [];
    debugPrint("[DoctorDetailsScreen _showAppointmentBookingDialog] Dialog shown. Initial selected date: $_selectedBookingDate");

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (modalContext) {
        bool isModalFirstLoad = true;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            if (isModalFirstLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && ctx.mounted) {
                  debugPrint("[DoctorDetailsScreen BookingDialog] First load, generating slots for $_selectedBookingDate");
                  _generateAvailableTimeSlots(_selectedBookingDate, modalSetState);
                  modalSetState(() => isModalFirstLoad = false);
                }
              });
            }
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(children: [
                Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom:12), decoration: BoxDecoration(color: AppColors.gray.withOpacity(0.4), borderRadius: BorderRadius.circular(10))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Book with Dr. $_doctorNickname', style: const TextStyle(color: AppColors.dark, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gray, size: 26), onPressed: () => Navigator.pop(ctx))
                  ]),
                ),
                const Divider(height: 20),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal:20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('1. Select Date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    const SizedBox(height: 10),
                    Card(elevation: 1.5, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: CalendarDatePicker(
                        initialDate: _selectedBookingDate,
                        firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), // Allow today
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        selectableDayPredicate: _isDoctorAvailableOnDay,
                        onDateChanged: (date) {
                          debugPrint("[DoctorDetailsScreen BookingDialog] Date changed to: $date");
                          modalSetState(() => _selectedBookingDate = date);
                          _generateAvailableTimeSlots(date, modalSetState);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('2. Select Available Time Slot', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    const SizedBox(height: 12),
                    if (_isLoadingBookingSlots) const Center(child: Padding(padding: EdgeInsets.all(20), child: LoadingIndicator(size: 30)))
                    else if (!_isDoctorAvailableOnDay(_selectedBookingDate) || _availableTimeSlotsForBooking.isEmpty)
                      Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.light.withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                          child: Text('No slots available for ${DateFormat('EEE, MMM d').format(_selectedBookingDate)}.', style: const TextStyle(color: AppColors.gray, fontSize: 15, fontStyle: FontStyle.italic), textAlign: TextAlign.center,))
                    else
                      GridView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.9),
                        itemCount: _availableTimeSlotsForBooking.length,
                        itemBuilder: (context, index) {
                          final timeSlot = _availableTimeSlotsForBooking[index];
                          final isBooked = _bookedTimeSlotsForSelectedDate.contains(timeSlot);
                          final isSelected = timeSlot == _selectedBookingTimeSlot;
                          return ChoiceChip(
                            label: Text(_formatTimeSlotDisplay(timeSlot), style: TextStyle(color: isSelected ? AppColors.white : (isBooked ? AppColors.gray.withOpacity(0.7) : AppColors.primary), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                            selected: isSelected,
                            onSelected: isBooked ? null : (selected) {
                              if(selected) modalSetState(() => _selectedBookingTimeSlot = timeSlot);
                              debugPrint("[DoctorDetailsScreen BookingDialog] Timeslot selected: $timeSlot, Is Booked: $isBooked");
                            },
                            backgroundColor: isBooked ? AppColors.gray.withOpacity(0.15) : AppColors.light.withOpacity(0.8),
                            selectedColor: AppColors.secondary,
                            disabledColor: AppColors.gray.withOpacity(0.15),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppColors.secondary : (isBooked ? AppColors.gray.withOpacity(0.3) : AppColors.primary.withOpacity(0.4)))),
                            showCheckmark: false,
                            elevation: isSelected ? 1 : 0,
                          );
                        },
                      ),
                  ]),
                )),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: (_selectedBookingTimeSlot == null || !_isDoctorAvailableOnDay(_selectedBookingDate)) ? null : () {
                      Navigator.pop(ctx);
                      _confirmAndBookAppointment(_selectedBookingDate, _selectedBookingTimeSlot!);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    child: const Text('Proceed to Confirmation'),
                  ),
                )
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndBookAppointment(DateTime selectedDate, String timeSlot) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to book an appointment.')));
      return;
    }
    debugPrint("[DoctorDetailsScreen _confirmAndBookAppointment] Confirming for $selectedDate at $timeSlot");

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Your Appointment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _confirmationRow(Icons.person_outline_rounded, 'Doctor:', 'Dr. $_doctorNickname'),
          _confirmationRow(Icons.calendar_today_rounded, 'Date:', DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
          _confirmationRow(Icons.access_time_rounded, 'Time:', _formatTimeSlotDisplay(timeSlot)),
          _confirmationRow(Icons.sell_outlined, 'Fee:', 'PKR ${_currentDoctorData['consultationFee']?.toStringAsFixed(0) ?? 'N/A'}'),
        ]),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white), child: const Text('Confirm & Book')),
        ],
      ),
    );

    if (confirm == true) {
      _bookAppointmentInFirestore(selectedDate, timeSlot, currentUser.uid);
    }
  }

  Widget _confirmationRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 15.5, color: AppColors.dark.withOpacity(0.8))),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.dark))),
      ]),
    );
  }

  Future<void> _bookAppointmentInFirestore(DateTime selectedDate, String timeSlot, String patientId) async {
    if(!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: LoadingIndicator(message: "Booking...")));
    debugPrint("[DoctorDetailsScreen _bookAppointmentInFirestore] Attempting to book for Dr ${widget.doctorId} by patient $patientId on $selectedDate at $timeSlot");

    final appointmentDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(timeSlot.split(':')[0]), int.parse(timeSlot.split(':')[1]));
    final int durationMinutes = _currentDoctorData['appointmentDurationMinutes'] as int? ?? 15;
    final DateTime appointmentEndTime = appointmentDateTime.add(Duration(minutes: durationMinutes));

    String patientNickname = 'Patient';
    try {
      DocumentSnapshot patientUserDoc = await _firestore.collection('users').doc(patientId).get();
      if (patientUserDoc.exists) patientNickname = (patientUserDoc.data() as Map<String,dynamic>)['nickname'] ?? 'Patient';
    } catch(e) { debugPrint("[DoctorDetailsScreen _bookAppointmentInFirestore] Error fetching patient nickname: $e");}

    final Map<String, dynamic> appointmentData = {
      'patientId': patientId,
      'doctorId': widget.doctorId,
      'doctorName': _doctorNickname,
      'specialty': _currentDoctorData['specialty'] ?? 'Consultation',
      'patientName': patientNickname,
      'date': Timestamp.fromDate(appointmentDateTime),
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'originalEndTime': Timestamp.fromDate(appointmentEndTime),
      'currentEndTime': Timestamp.fromDate(appointmentEndTime),
      'status': 'scheduled',
      'consultationFee': _currentDoctorData['consultationFee'] ?? 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'videoCallUsed': false, 'doctorsNote': '', 'timesExtended': 0, 'callRoomId': null,
    };

    try {
      // Check for existing appointment at the exact same slot again right before writing
      QuerySnapshot existing = await _firestore.collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(appointmentDateTime)) // Exact start time
          .where('status', whereIn: ['scheduled', 'rescheduled_by_doctor', 'rescheduled_by_patient', 'active', 'ongoing'])
          .limit(1).get();

      if (mounted) Navigator.pop(context); // Pop loading dialog

      if (existing.docs.isNotEmpty) {
        debugPrint("[DoctorDetailsScreen _bookAppointmentInFirestore] Slot conflict found for Dr ${widget.doctorId} at $appointmentDateTime");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This time slot was just booked by someone else. Please select another.'), backgroundColor: AppColors.warning, duration: Duration(seconds: 3)));
        return;
      }

      await _firestore.collection('appointments').add(appointmentData);
      debugPrint("[DoctorDetailsScreen _bookAppointmentInFirestore] Appointment booked successfully. Appt Data: $appointmentData");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: AppColors.success, duration: Duration(seconds: 3)));
      }
    } catch (e) {
      if(mounted) Navigator.pop(context);
      debugPrint("[DoctorDetailsScreen _bookAppointmentInFirestore] Error in Firestore: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book appointment: ${e.toString()}'), backgroundColor: AppColors.error, duration: Duration(seconds: 3)));
    }
  }
}

// Helper extension for DateTime comparison
extension DateOnlyCompare on DateTime {
  bool isSameDateAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}