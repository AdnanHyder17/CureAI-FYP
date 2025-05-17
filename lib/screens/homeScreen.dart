// lib/screens/homeScreen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:p1/theme.dart';
import 'package:p1/widgets/loading_indicator.dart'; // Assuming you have this
import 'package:p1/screens/login_screen.dart';
import 'package:p1/screens/profile_screen.dart';
import 'package:p1/screens/doctor_list_screen.dart';
import 'package:p1/screens/doctor_detail.page.dart';
import 'package:p1/screens/chat_list_screen.dart';
import 'package:p1/screens/ai_chatbot_screen.dart';
// Removed map_Screen.dart as it was a placeholder and not in bottom nav

// --- Carousel Widget ---
class HomeCarouselWidget extends StatefulWidget {
  const HomeCarouselWidget({super.key});

  @override
  State<HomeCarouselWidget> createState() => _HomeCarouselWidgetState();
}

class _HomeCarouselWidgetState extends State<HomeCarouselWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentCarouselPage = 0;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'assets/image1.jpg',
      'title': 'Your Health Journey',
      'description': 'Access doctors, track appointments, and stay informed.',
    },
    {
      'image': 'assets/image2.jpg',
      'title': 'Expert Consultations',
      'description': 'Connect with specialized doctors for your needs.',
    },
    {
      'image': 'assets/image3.jpg',
      'title': 'AI Health Assistant',
      'description': 'Get quick answers and guidance from our AI chatbot.',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_carouselItems.isNotEmpty) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 7), (Timer timer) {
      if (!mounted || !_pageController.hasClients || _carouselItems.isEmpty) return;
      int nextPage = _currentCarouselPage + 1;
      if (nextPage >= _carouselItems.length) {
        nextPage = 0; // Loop back to the first item
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carouselItems.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("Promotional content coming soon!")));
    }
    return SizedBox(
      height: 200, // Adjusted height
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentCarouselPage = index);
            },
            itemCount: _carouselItems.length,
            itemBuilder: (context, index) {
              final item = _carouselItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0), // Added margin
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0), // Rounded corners
                  image: DecorationImage(
                    image: AssetImage(item['image']),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // This AssetImage itself doesn't have an onError like NetworkImage.
                      // The errorBuilder is for the parent Image widget if you were using one.
                      // For AssetImage, ensure paths are correct.
                    },
                  ),
                ),
                child: Container( // Gradient overlay
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)],
                      stops: const [0.4, 0.6, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1, 1))],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            color: AppColors.white, fontSize: 15,
                            shadows: [Shadow(blurRadius: 1.0, color: Colors.black38, offset: Offset(1, 1))],
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 12, // Adjusted position
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _carouselItems.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 9, dotWidth: 9, activeDotColor: AppColors.white,
                  dotColor: AppColors.white.withOpacity(0.5), expansionFactor: 3, spacing: 7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// --- End Carousel Widget ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _nickname;
  String? _profileImageUrl; // For displaying user avatar
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0; // 0: Home, 1: Doctors, 2: Chat, 3: Profile

  final List<Widget> _screens = [
    const _HomeContent(), // Extracted home content
    const DoctorListingScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nickname = data['nickname'] as String?;
            _profileImageUrl = data['profileImageUrl'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user details for HomeScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load user details: ${e.toString()}'), backgroundColor: AppColors.error),
        );
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
                await _auth.signOut();
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, // Use error color for destructive action
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? (_nickname != null ? 'Hello, $_nickname!' : 'CureAI Home') :
          _currentIndex == 1 ? 'Find a Doctor' :
          _currentIndex == 2 ? 'My Chats' : 'My Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _confirmLogout();
                // Add other options like 'Settings' if needed
              },
              icon: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.8),
                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                radius: 18,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) && _nickname != null && _nickname!.isNotEmpty
                    ? Text(_nickname![0].toUpperCase(), style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))
                    : ((_profileImageUrl == null || _profileImageUrl!.isEmpty) ? const Icon(Icons.person_outline, size: 20, color: AppColors.white) : null),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
          ),
        ],
        backgroundColor: AppColors.primary,
        elevation: _currentIndex == 0 ? 0 : 2, // No elevation for home appbar
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
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
          padding: const EdgeInsets.all(10.0), // Adjust padding for your logo
          child: Image.asset(
            'assets/logo_icon_white.png', // Ensure this is a white/light version of your logo for dark FAB
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.bubble_chart_outlined, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.white,
        elevation: 8.0, // Add some elevation for definition
        child: SizedBox(
          height: 65, // Standard BottomNavigationBar height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildBottomNavItem(icon: Icons.home_filled, label: 'Home', index: 0),
              _buildBottomNavItem(icon: Icons.medical_services_rounded, label: 'Doctors', index: 1),
              const SizedBox(width: 48), // The FAB notch space
              _buildBottomNavItem(icon: Icons.chat_bubble_rounded, label: 'Chats', index: 2),
              _buildBottomNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(20), // For splash effect
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

// --- Extracted Home Content Widget ---
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This method is now local to _HomeContentState
  Future<void> _fetchUserDetailsForRefresh() async {
    // This is a placeholder if _HomeContent needs to refresh its own specific data.
    // The parent HomeScreen already fetches nickname and profile image.
    // If there's other data specific to this tab, fetch it here.
    if (mounted) setState(() {}); // Trigger rebuild if data changes
  }


  Future<void> _deleteAppointment(String appointmentId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Appointment?', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.', style: TextStyle(color: AppColors.dark)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep It', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).update({
          'status': 'cancelled_by_patient', // More specific status
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Instead of deleting, update status. If you must delete:
        // await _firestore.collection('appointments').doc(appointmentId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully.'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel appointment: ${e.toString()}'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _formatTimeSlotDisplay(BuildContext context, String? rawTimeSlot) {
    if (rawTimeSlot == null || rawTimeSlot.isEmpty) return 'N/A';
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot; // Invalid format
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return rawTimeSlot; // Invalid numbers
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      debugPrint("Error formatting time slot '$rawTimeSlot': $e");
      return rawTimeSlot; // Fallback to raw string on error
    }
  }

  Future<Map<String, dynamic>?> _fetchDoctorAvailabilityForReschedule(String doctorId) async {
    try {
      DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doctorDoc.exists && doctorDoc.data() != null) {
        return (doctorDoc.data() as Map<String, dynamic>)['availability'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint("Error fetching doctor availability for reschedule: $e");
    }
    return null;
  }

  bool _isDoctorAvailableOnDayForReschedule(DateTime day, Map<String, dynamic>? availability) {
    if (availability == null) return false;
    final String dayOfWeek = DateFormat('EEEE').format(day);
    if (availability.containsKey(dayOfWeek)) {
      final dayRanges = availability[dayOfWeek] as List<dynamic>?;
      return dayRanges != null && dayRanges.isNotEmpty;
    }
    return false;
  }

  Future<void> _rescheduleAppointment(String appointmentId) async {
    if (!mounted) return;

    try {
      DocumentSnapshot appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      if (!mounted || !appointmentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment not found.')));
        return;
      }

      Map<String, dynamic> appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      String doctorId = appointmentData['doctorId'];
      String currentDoctorName = appointmentData['doctorName'] ?? 'Doctor';
      int durationMinutes = appointmentData['durationMinutes'] ?? 15; // Get existing duration

      Map<String, dynamic>? doctorAvailability = await _fetchDoctorAvailabilityForReschedule(doctorId);

      DateTime initialRescheduleDate = (appointmentData['date'] as Timestamp).toDate();
      if (initialRescheduleDate.isBefore(DateTime.now().subtract(const Duration(days:1)))) {
        initialRescheduleDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      }

      DateTime firstAvailableRescheduleDay = initialRescheduleDate;
      int daysToScanReschedule = 0;
      while (doctorAvailability != null && !_isDoctorAvailableOnDayForReschedule(firstAvailableRescheduleDay, doctorAvailability) && daysToScanReschedule < 60) {
        firstAvailableRescheduleDay = firstAvailableRescheduleDay.add(const Duration(days: 1));
        daysToScanReschedule++;
      }

      DateTime selectedRescheduleDate = firstAvailableRescheduleDay;
      String? selectedRescheduleTimeSlot;
      List<String> availableSlotsForReschedule = [];
      List<String> bookedSlotsForSelectedRescheduleDate = [];
      bool isLoadingRescheduleSlots = true;
      bool isModalFirstLoadReschedule = true;

      void updateRescheduleSlotsStateful(DateTime date, StateSetter modalSetState) async {
        modalSetState(() {
          isLoadingRescheduleSlots = true;
          availableSlotsForReschedule = [];
          selectedRescheduleTimeSlot = null;
        });

        final String dayOfWeek = DateFormat('EEEE').format(date);
        List<Map<String, String>> doctorDayRanges = [];

        if (doctorAvailability != null && doctorAvailability.containsKey(dayOfWeek)) {
          try {
            doctorDayRanges = List<Map<String, String>>.from(
                (doctorAvailability[dayOfWeek] as List<dynamic>).map(
                        (item) => Map<String, String>.from(item as Map<dynamic, dynamic>)));
          } catch (e) { debugPrint("Error parsing doctor availability for reschedule on $dayOfWeek: $e"); }
        }

        List<String> generatedSlots = [];
        if (doctorDayRanges.isNotEmpty) {
          for (var range in doctorDayRanges) {
            final startTimeParts = range['start']?.split(':');
            final endTimeParts = range['end']?.split(':');
            if (startTimeParts?.length == 2 && endTimeParts?.length == 2) {
              try {
                TimeOfDay startTime = TimeOfDay(hour: int.parse(startTimeParts![0]), minute: int.parse(startTimeParts[1]));
                TimeOfDay endTime = TimeOfDay(hour: int.parse(endTimeParts![0]), minute: int.parse(endTimeParts[1]));
                DateTime currentSlotTime = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                DateTime rangedEndTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

                while (currentSlotTime.add(Duration(minutes: durationMinutes)).isBefore(rangedEndTime) || currentSlotTime.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(rangedEndTime)) {
                  bool isSlotInPast = date.isSameDateAs(DateTime.now()) &&
                      currentSlotTime.isBefore(DateTime.now().add(const Duration(minutes: 5)));
                  if (!isSlotInPast) {
                    generatedSlots.add('${currentSlotTime.hour.toString().padLeft(2, '0')}:${currentSlotTime.minute.toString().padLeft(2, '0')}');
                  }
                  currentSlotTime = currentSlotTime.add(const Duration(minutes: 15)); // Slot generation interval
                }
              } catch (e) { debugPrint("Error generating time slots for range $range: $e"); }
            }
          }
        }

        final QuerySnapshot bookedSnapshot = await _firestore.collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
            .where('date', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day).add(const Duration(days: 1))))
            .where(FieldPath.documentId, isNotEqualTo: appointmentId)
            .get();
        bookedSlotsForSelectedRescheduleDate = bookedSnapshot.docs.map((doc) => doc['timeSlot'] as String).toList();

        modalSetState(() {
          availableSlotsForReschedule = generatedSlots;
          isLoadingRescheduleSlots = false;
        });
      }

      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (BuildContext ctx, StateSetter modalSetState) {
              if (isModalFirstLoadReschedule) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && ctx.mounted) {
                    updateRescheduleSlotsStateful(selectedRescheduleDate, modalSetState);
                    modalSetState(() => isModalFirstLoadReschedule = false);
                  }
                });
              }
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Reschedule Appointment', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.white), onPressed: () => Navigator.pop(ctx))
                    ]),
                  ),
                  Expanded(child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Select New Date for Dr. $currentDoctorName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      const SizedBox(height: 12),
                      Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: CalendarDatePicker(
                          initialDate: selectedRescheduleDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          selectableDayPredicate: (day) => _isDoctorAvailableOnDayForReschedule(day, doctorAvailability),
                          onDateChanged: (date) {
                            modalSetState(() => selectedRescheduleDate = date);
                            updateRescheduleSlotsStateful(date, modalSetState);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Select New Time Slot', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                      const SizedBox(height: 12),
                      if (isLoadingRescheduleSlots) const Center(child: Padding(padding: EdgeInsets.all(16), child: LoadingIndicator()))
                      else if (doctorAvailability == null || !_isDoctorAvailableOnDayForReschedule(selectedRescheduleDate, doctorAvailability))
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text('Doctor is not available on ${DateFormat('EEE, MMM d').format(selectedRescheduleDate)}.', style: const TextStyle(color: AppColors.gray, fontSize: 15))))
                      else if (availableSlotsForReschedule.isEmpty)
                          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('No available slots for ${DateFormat('EEE, MMM d').format(selectedRescheduleDate)}.', style: const TextStyle(color: AppColors.gray, fontSize: 15))))
                        else
                          GridView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.8),
                            itemCount: availableSlotsForReschedule.length,
                            itemBuilder: (context, index) {
                              final timeSlot = availableSlotsForReschedule[index];
                              final isBooked = bookedSlotsForSelectedRescheduleDate.contains(timeSlot);
                              final isSelected = timeSlot == selectedRescheduleTimeSlot;
                              return GestureDetector(
                                onTap: isBooked ? null : () => modalSetState(() => selectedRescheduleTimeSlot = timeSlot),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isBooked ? AppColors.gray.withOpacity(0.2) : isSelected ? AppColors.secondary : AppColors.light.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? AppColors.primary : (isBooked ? AppColors.gray.withOpacity(0.4) : AppColors.primary.withOpacity(0.4)), width: isSelected ? 2 : 1.2),
                                    boxShadow: isSelected ? [BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 5, offset: const Offset(0,2))] : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, offset: const Offset(0,1))],
                                  ),
                                  child: Center(child: Text(_formatTimeSlotDisplay(context, timeSlot), style: TextStyle(color: isBooked ? AppColors.dark.withOpacity(0.4) : isSelected ? AppColors.white : AppColors.primary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13, decoration: isBooked ? TextDecoration.lineThrough : TextDecoration.none))),
                                ),
                              );
                            },
                          ),
                    ]),
                  )),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(ctx).padding.bottom + 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
                      label: const Text('Confirm Reschedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: (selectedRescheduleTimeSlot == null || doctorAvailability == null || !_isDoctorAvailableOnDayForReschedule(selectedRescheduleDate, doctorAvailability))
                          ? null
                          : () async {
                        Navigator.pop(ctx); // Close modal
                        final timeParts = selectedRescheduleTimeSlot!.split(':');
                        final newAppointmentDateTime = DateTime(selectedRescheduleDate.year, selectedRescheduleDate.month, selectedRescheduleDate.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
                        final newCurrentEndTime = newAppointmentDateTime.add(Duration(minutes: durationMinutes));

                        await _firestore.collection('appointments').doc(appointmentId).update({
                          'date': Timestamp.fromDate(newAppointmentDateTime),
                          'timeSlot': selectedRescheduleTimeSlot,
                          'status': 'rescheduled_by_patient',
                          'updatedAt': FieldValue.serverTimestamp(),
                          'currentEndTime': Timestamp.fromDate(newCurrentEndTime), // Update current end time
                          // Reset other call-related fields if necessary
                          'videoCallUsed': false, 'doctorsNote': '', 'timesExtended': 0,
                        });
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rescheduled successfully.'), backgroundColor: AppColors.success));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, minimumSize: const Size(double.infinity, 52), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                    ),
                  )
                ]),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error in _rescheduleAppointment: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reschedule: ${e.toString()}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _checkAndUpdateAppointmentStatus(DocumentSnapshot appointmentDoc) async {
    if (!mounted) return;
    Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;
    String currentStatus = data['status'] ?? '';
    Timestamp? currentEndTimeStamp = data['currentEndTime'] as Timestamp?;

    if ((currentStatus == 'scheduled' || currentStatus == 'rescheduled_by_patient' || currentStatus == 'rescheduled_by_doctor') && currentEndTimeStamp != null) {
      DateTime currentEndTime = currentEndTimeStamp.toDate();
      if (DateTime.now().isAfter(currentEndTime)) {
        // Check if a call actually happened (simplified check)
        bool callUsed = data['videoCallUsed'] as bool? ?? false;
        String newStatus = callUsed ? 'completed' : 'missed';

        try {
          await _firestore.collection('appointments').doc(appointmentDoc.id)
              .update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
          debugPrint("Appointment ${appointmentDoc.id} status updated to $newStatus by client.");
        } catch (e) {
          debugPrint("Failed to update appointment status for ${appointmentDoc.id}: $e");
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // This should ideally not happen if auth state is managed properly before reaching HomeScreen
      return const Center(child: Text("User not logged in."));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchUserDetailsForRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures refresh works even if content is small
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 400),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 16.0), // Add padding around carousel
                child: HomeCarouselWidget(),
              ),
              _buildAppointmentsSection(
                title: 'Upcoming Appointments',
                icon: Icons.event_note_rounded,
                query: _firestore.collection('appointments')
                    .where('patientId', isEqualTo: currentUser.uid)
                    .where('status', whereIn: ['scheduled', 'rescheduled_by_doctor', 'rescheduled_by_patient']) // Active statuses
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1)))) // Show appointments starting soon or in future
                    .orderBy('date')
                    .limit(5)
                    .snapshots(),
                isUpcoming: true,
              ),
              const SizedBox(height: 24),
              _buildAppointmentsSection(
                title: 'Past Appointments',
                icon: Icons.history_rounded,
                query: _firestore.collection('appointments')
                    .where('patientId', isEqualTo: currentUser.uid)
                    .where('status', whereIn: ['completed', 'cancelled_by_patient', 'cancelled_by_doctor', 'missed']) // Concluded statuses
                    .orderBy('date', descending: true)
                    .limit(5)
                    .snapshots(),
                isUpcoming: false,
              ),
              const SizedBox(height: 30), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection({
    required String title,
    required IconData icon,
    required Stream<QuerySnapshot> query,
    required bool isUpcoming,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
              ]),
              if (!isUpcoming) // "View All" for previous appointments (can be implemented later)
                TextButton(
                  onPressed: () { /* TODO: Navigate to full list of past appointments */
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("View all past appointments (Not Implemented)")));
                  },
                  child: const Text("View All", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: query,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 120, child: Center(child: LoadingIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoAppointmentsCard(isUpcoming);
              }

              // Consistently check and update status for all appointments fetched by these streams
              // This will handle transitions from scheduled -> missed/completed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    // Check and update status regardless of whether it's upcoming or past list initially.
                    // The status update might move it between lists.
                    _checkAndUpdateAppointmentStatus(doc);
                  }
                }
              });

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  // Ensure data is Map<String, dynamic>
                  var appointmentData = doc.data();
                  if (appointmentData is Map<String, dynamic>) {
                    return _buildAppointmentCard(appointmentData, doc.id, isUpcoming);
                  } else {
                    // Handle cases where data is not in the expected format, perhaps log or show an error item
                    return const ListTile(title: Text("Error: Invalid appointment data"));
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoAppointmentsCard(bool isUpcoming) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            Icon(isUpcoming ? Icons.event_busy_outlined : Icons.history_toggle_off_outlined, color: AppColors.gray, size: 50),
            const SizedBox(height: 16),
            Text(isUpcoming ? 'No upcoming appointments.' : 'No past appointments found.', style: const TextStyle(color: AppColors.dark, fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(isUpcoming ? 'Book a new consultation to see it here.' : 'Your appointment history will appear here.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray, fontSize: 14)),
            if (isUpcoming) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Accessing _currentIndex from parent HomeScreen is not direct.
                  // A better way is to use a callback or a state management solution.
                  // For now, let's assume we want to switch to the DoctorListingScreen tab.
                  // This requires a way to communicate to the parent HomeScreen.
                  // Simplest for now: directly navigate, but this breaks the tab structure.
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorListingScreen()));
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('Book an Appointment'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String appointmentId, bool isUpcoming) {
    DateTime appointmentDate = (data['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('EEE, MMM d, yyyy').format(appointmentDate);
    String formattedTime = _formatTimeSlotDisplay(context, data['timeSlot'] as String?);
    String doctorName = data['doctorName'] as String? ?? 'Dr. Unknown';
    String specialty = data['specialty'] as String? ?? 'Consultation';
    String status = (data['status'] as String? ?? (isUpcoming ? 'Scheduled' : 'Completed')).replaceAll('_', ' ').capitalizeFirstLetter();
    String doctorId = data['doctorId'] as String? ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (data['status']?.toLowerCase()) {
      case 'scheduled':
      case 'rescheduled_by_doctor':
      case 'rescheduled_by_patient':
        statusColor = AppColors.primary;
        statusIcon = Icons.alarm_on_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success;
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

    Widget cardContent = Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () async {
          if (doctorId.isNotEmpty) {
            try {
              DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
              if (mounted && doctorDoc.exists) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctorId: doctorId, doctorData: doctorDoc.data() as Map<String, dynamic>)));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor details not found.')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching doctor details: $e')));
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 26,
                  child: Icon(isUpcoming ? Icons.medical_services_outlined : Icons.history_edu_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doctorName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(specialty, style: TextStyle(fontSize: 14, color: AppColors.dark.withOpacity(0.75)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Divider(color: AppColors.gray.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _infoChip(Icons.calendar_today_rounded, formattedDate, AppColors.secondary),
                _infoChip(Icons.access_time_filled_rounded, formattedTime, AppColors.secondary),
              ]),
            ],
          ),
        ),
      ),
    );

    bool canReschedule = isUpcoming && (data['status'] == 'scheduled' || data['status'] == 'rescheduled_by_doctor');
    bool canCancel = isUpcoming && (data['status'] == 'scheduled' || data['status'] == 'rescheduled_by_doctor' || data['status'] == 'rescheduled_by_patient');


    if (isUpcoming && (canReschedule || canCancel)) {
      return Slidable(
        key: Key(appointmentId),
        endActionPane: ActionPane(
          motion: const StretchMotion(), // Changed motion
          extentRatio: 0.55, // Adjusted extent
          children: [
            if(canReschedule)
              SlidableAction(
                onPressed: (_) => _rescheduleAppointment(appointmentId),
                backgroundColor: AppColors.warning.withOpacity(0.9),
                foregroundColor: Colors.white,
                icon: Icons.edit_calendar_rounded,
                label: 'Reschedule',
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
            if(canCancel)
              SlidableAction(
                onPressed: (_) => _deleteAppointment(appointmentId), // This now updates status to cancelled
                backgroundColor: AppColors.error.withOpacity(0.9),
                foregroundColor: Colors.white,
                icon: Icons.cancel_presentation_rounded, // Changed icon
                label: 'Cancel',
                borderRadius: canReschedule ? BorderRadius.zero : const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
          ],
        ),
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _infoChip(IconData icon, String text, Color iconColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: iconColor, size: 17),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 13.5, color: AppColors.dark.withOpacity(0.9), fontWeight: FontWeight.w500)),
    ]);
  }
}

// Helper extension for String capitalization
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

