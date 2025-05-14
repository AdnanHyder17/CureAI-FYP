import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import 'doctor_detail.page.dart';
import 'login_screen.dart';
import 'map_Screen.dart';
import 'profile_screen.dart';
import 'doctor_list_screen.dart';
import 'package:p1/theme.dart';
import 'chat_list_screen.dart';
import 'package:p1/screens/ai_chatbot_screen.dart';

// --- Standalone Carousel Widget ---
class CarouselWidget extends StatefulWidget {
  const CarouselWidget({super.key});

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentCarouselPage = 0;

  // Ensure these asset paths are correct and images are in your pubspec.yaml
  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'assets/image1.jpg',
      'title': 'Regular Check-ups',
      'description': 'Stay healthy with routine medical check-ups',
    },
    {
      'image': 'assets/image2.jpg',
      'title': 'Specialist Consultations',
      'description': 'Connect with top specialists in their field',
    },
    {
      'image': 'assets/image3.jpg',
      'title': 'Mental Wellness',
      'description': 'Take care of your mental health with our experts',
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
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted || !_pageController.hasClients || _carouselItems.isEmpty) return;
      int nextPage = _currentCarouselPage + 1;
      if (nextPage >= _carouselItems.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      // onPageChanged will update _currentCarouselPage
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
      return const SizedBox(height: 220, child: Center(child: Text("No items for carousel")));
    }
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentCarouselPage = index;
                });
              }
            },
            itemCount: _carouselItems.length,
            itemBuilder: (context, index) {
              final item = _carouselItems[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.light,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: AppColors.gray, size: 50),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.4, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1, 1))
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['description'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            shadows: [
                              Shadow(blurRadius: 1.0, color: Colors.black38, offset: Offset(1, 1))
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _carouselItems.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: AppColors.secondary,
                  dotColor: AppColors.white.withOpacity(0.6),
                  expansionFactor: 2.5,
                  spacing: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// --- End Standalone Carousel Widget ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _nickname;
  String? _role; // To determine user type if needed for UI variations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0; // 0: Home, 1: Chat, 2: Doctors, 3: Map, 4: Profile

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    // _updateAppointmentsWithDoctorInfo(); // Call this only if you need to backfill old appointments.
    // For new appointments, doctorName and specialty should be
    // denormalized at the time of booking.

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

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
          setState(() {
            _nickname = userDoc.get('nickname') as String?;
            _role = userDoc.get('role') as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user details: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No', style: TextStyle(color: AppColors.gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatTimeSlotDisplay(String? rawTimeSlot) {
    if (rawTimeSlot == null || rawTimeSlot.isEmpty) return 'N/A';
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      final timeOfDay = TimeOfDay(hour: hour, minute: minutes);
      return timeOfDay.format(context);
    } catch (e) { return rawTimeSlot; }
  }

  Future<void> _rescheduleAppointment(String appointmentId) async {
    if (!mounted) return; // Ensure widget is still in the tree

    try {
      DocumentSnapshot appointmentDoc =
      await _firestore.collection('appointments').doc(appointmentId).get();

      if (!mounted || !appointmentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment not found or screen no longer active.')),
        );
        return;
      }

      Map<String, dynamic> appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      String doctorId = appointmentData['doctorId'];
      String currentDoctorName = appointmentData['doctorName'] ?? 'Doctor';

      Map<String, dynamic>? doctorAvailability = await _fetchDoctorAvailabilityForReschedule(doctorId);

      DateTime initialRescheduleDate = (appointmentData['date'] as Timestamp).toDate();
      // Ensure initial date is not in the past for rescheduling
      if (initialRescheduleDate.isBefore(DateTime.now().subtract(const Duration(days:1)))) { // Allow rescheduling for today if not past
        initialRescheduleDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      }
      // Find first available day for rescheduling, starting from today or the original appointment day if it's in the future
      DateTime firstAvailableRescheduleDay = initialRescheduleDate;
      int daysToScanReschedule = 0;
      while (doctorAvailability != null && !_isDoctorAvailableOnDayForReschedule(firstAvailableRescheduleDay, doctorAvailability) && daysToScanReschedule < 60) {
        firstAvailableRescheduleDay = firstAvailableRescheduleDay.add(const Duration(days: 1));
        daysToScanReschedule++;
      }
      // If no available day is found within 60 days, it will stick to 60 days out.
      // The selectableDayPredicate will handle disabling them in the picker.

      DateTime selectedRescheduleDate = firstAvailableRescheduleDay;
      String? selectedRescheduleTimeSlot;
      List<String> availableSlotsForReschedule = [];
      List<String> bookedSlotsForSelectedRescheduleDate = [];
      bool isLoadingRescheduleSlots = true;
      bool isModalFirstLoadReschedule = true;

      // Helper function within _rescheduleAppointment to update slots
      void updateRescheduleSlotsStateful(DateTime date, StateSetter modalSetState) async {
        modalSetState(() {
          isLoadingRescheduleSlots = true;
          availableSlotsForReschedule = [];
          selectedRescheduleTimeSlot = null; // Reset selected time slot when date changes
        });

        final String dayOfWeek = DateFormat('EEEE').format(date); // e.g., "Monday"
        List<Map<String, String>> doctorDayRanges = [];

        if (doctorAvailability != null && doctorAvailability.containsKey(dayOfWeek)) {
          try {
            doctorDayRanges = List<Map<String, String>>.from(
                (doctorAvailability[dayOfWeek] as List<dynamic>).map(
                        (item) => Map<String, String>.from(item as Map<dynamic, dynamic>)));
          } catch (e) {
            debugPrint("Error parsing doctor availability for reschedule on $dayOfWeek: $e");
            doctorDayRanges = [];
          }
        }

        List<String> generatedSlots = [];
        if (doctorDayRanges.isNotEmpty) {
          for (var range in doctorDayRanges) {
            final startTimeParts = range['start']?.split(':');
            final endTimeParts = range['end']?.split(':');
            if (startTimeParts != null && startTimeParts.length == 2 && endTimeParts != null && endTimeParts.length == 2) {
              try {
                TimeOfDay startTime = TimeOfDay(hour: int.parse(startTimeParts[0]), minute: int.parse(startTimeParts[1]));
                TimeOfDay endTime = TimeOfDay(hour: int.parse(endTimeParts[0]), minute: int.parse(endTimeParts[1]));
                DateTime currentSlotTime = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                DateTime rangedEndTime = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

                while (currentSlotTime.isBefore(rangedEndTime)) {
                  bool isSlotInPast = date.isSameDateAs(DateTime.now()) &&
                      currentSlotTime.isBefore(DateTime.now().add(const Duration(minutes: 5))); // 5 min buffer
                  if (!isSlotInPast) {
                    generatedSlots.add('${currentSlotTime.hour.toString().padLeft(2, '0')}:${currentSlotTime.minute.toString().padLeft(2, '0')}');
                  }
                  currentSlotTime = currentSlotTime.add(const Duration(minutes: 15)); // Assuming 15-minute slots
                }
              } catch (e) {
                debugPrint("Error generating time slots for range $range: $e");
              }
            }
          }
        }

        final QuerySnapshot bookedSnapshot = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
            .where('date', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day).add(const Duration(days: 1))))
            .where(FieldPath.documentId, isNotEqualTo: appointmentId) // Exclude the current appointment being rescheduled
            .get();
        bookedSlotsForSelectedRescheduleDate = bookedSnapshot.docs.map((doc) => doc['timeSlot'] as String).toList();

        modalSetState(() {
          availableSlotsForReschedule = generatedSlots;
          isLoadingRescheduleSlots = false;
        });
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (BuildContext ctx, StateSetter modalSetState) {
              if (isModalFirstLoadReschedule) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && ctx.mounted) {
                    updateRescheduleSlotsStateful(selectedRescheduleDate, modalSetState);
                    modalSetState(() {
                      isModalFirstLoadReschedule = false;
                    });
                  }
                });
              }

              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Reschedule Appointment', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: AppColors.white), onPressed: () => Navigator.pop(ctx))
                      ]),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select New Date for Dr. $currentDoctorName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: CalendarDatePicker(
                                initialDate: selectedRescheduleDate,
                                firstDate: DateTime.now(), // Prevent selecting past dates
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                                selectableDayPredicate: (day) => _isDoctorAvailableOnDayForReschedule(day, doctorAvailability),
                                onDateChanged: (date) {
                                  modalSetState(() { selectedRescheduleDate = date; });
                                  updateRescheduleSlotsStateful(date, modalSetState);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Select New Time Slot', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
                            const SizedBox(height: 12),
                            if (isLoadingRescheduleSlots)
                              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)))
                            else if (doctorAvailability == null || !_isDoctorAvailableOnDayForReschedule(selectedRescheduleDate, doctorAvailability))
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text('Doctor is not available on ${DateFormat('EEE, MMM d').format(selectedRescheduleDate)}.', style: const TextStyle(color: AppColors.gray, fontSize: 15))),
                              )
                            else if (availableSlotsForReschedule.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: AppColors.light.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text('No available slots for ${DateFormat('EEE, MMM d').format(selectedRescheduleDate)}.', style: const TextStyle(color: AppColors.gray, fontSize: 15))),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                        child: Center(child: Text(_aformatTimeSlot(timeSlot) ?? timeSlot, style: TextStyle(color: isBooked ? AppColors.dark.withOpacity(0.4) : isSelected ? AppColors.white : AppColors.primary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13, decoration: isBooked ? TextDecoration.lineThrough : TextDecoration.none))),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, MediaQuery.of(ctx).padding.bottom + 16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 20),
                        label: const Text('Confirm Reschedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: (selectedRescheduleTimeSlot == null || doctorAvailability == null || !_isDoctorAvailableOnDayForReschedule(selectedRescheduleDate, doctorAvailability))
                            ? null
                            : () async {
                          Navigator.pop(ctx); // Close modal bottom sheet

                          final timeParts = selectedRescheduleTimeSlot!.split(':');
                          final newAppointmentDateTime = DateTime(
                              selectedRescheduleDate.year, selectedRescheduleDate.month, selectedRescheduleDate.day,
                              int.parse(timeParts[0]), int.parse(timeParts[1])
                          );

                          // Fetch latest doctor name and specialty in case they were updated
                          String latestDoctorName = appointmentData['doctorName'];
                          String latestSpecialty = appointmentData['specialty'];
                          try {
                            DocumentSnapshot doctorUserDoc = await _firestore.collection('users').doc(doctorId).get();
                            DocumentSnapshot doctorProfileDoc = await _firestore.collection('doctors').doc(doctorId).get();
                            if (doctorUserDoc.exists) {
                              latestDoctorName = (doctorUserDoc.data() as Map<String, dynamic>)['nickname'] ?? latestDoctorName;
                            }
                            if (doctorProfileDoc.exists) {
                              latestSpecialty = (doctorProfileDoc.data() as Map<String, dynamic>)['specialty'] ?? latestSpecialty;
                            }
                          } catch (e) {
                            debugPrint('Error fetching latest doctor details for reschedule: $e');
                          }

                          await _firestore.collection('appointments').doc(appointmentId).update({
                            'date': Timestamp.fromDate(newAppointmentDateTime),
                            'timeSlot': selectedRescheduleTimeSlot,
                            'status': 'rescheduled', // Ensure this status is handled by communication eligibility logic
                            'updatedAt': FieldValue.serverTimestamp(),
                            'doctorName': latestDoctorName,
                            'specialty': latestSpecialty,
                            // Reset fields related to a completed/ongoing call if necessary
                            'videoCallUsed': false,
                            'doctorsNote': '',
                            'timesExtended': 0, // Reset extension count for new slot
                            // Recalculate originalEndTime and currentEndTime based on new start time and duration
                            'durationMinutes': appointmentData['durationMinutes'] ?? 15, // Keep existing or default duration
                            'originalEndTime': Timestamp.fromDate(newAppointmentDateTime.add(Duration(minutes: appointmentData['durationMinutes'] ?? 15))),
                            'currentEndTime': Timestamp.fromDate(newAppointmentDateTime.add(Duration(minutes: appointmentData['durationMinutes'] ?? 15))),
                          });

                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rescheduled successfully'), backgroundColor: AppColors.success));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          textStyle: const TextStyle(letterSpacing: 0.5),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error in _rescheduleAppointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule appointment: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }



  String _aformatTimeSlot(String? rawTimeSlot) { // Made rawTimeSlot nullable
    if (rawTimeSlot == null || rawTimeSlot.isEmpty) return 'N/A';
    try {
      final parts = rawTimeSlot.split(':');
      if (parts.length != 2) return rawTimeSlot;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0; // Corrected typo: tryPArse to tryParse
      String minuteStr = minutes.toString().padLeft(2, '0');
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12; // Handles 12 PM and 12 AM correctly
      if (hour == 0) hour = 12; // Convert 0 hour to 12 for AM/PM
      return '$hour:$minuteStr $period';
    } catch (e) { return rawTimeSlot; }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _nickname != null ? 'Welcome, $_nickname!' : 'Welcome!',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.onPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'logout') _confirmLogout();
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.error, size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                backgroundColor: AppColors.secondary,
                radius: 20,
                child: Text(
                  _nickname?.isNotEmpty == true ? _nickname![0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.onSecondary, // Ensure this contrasts with AppColors.secondary
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: AppColors.primary,
        elevation: 2, // Added slight elevation
      ),
      body: IndexedStack( // Use IndexedStack to keep state of other screens
        index: _currentIndex,
        children: [
          _buildHomeContent(), // Your main home content for index 0
          const ChatListScreen(), // For index 1
          const DoctorListingScreen(), // For index 2
          const MapScreen(), // For index 3 (Placeholder)
          const ProfileScreen(), // For index 4
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatbotScreen()));
        },
        backgroundColor: AppColors.secondary, // Highlight color
        foregroundColor: AppColors.primary,   // Icon color
        elevation: 4.0,
        shape: const CircleBorder(), // Or StadiumBorder(), etc.
        child: Padding( // Add padding if your logo needs it
          padding: const EdgeInsets.all(8.0), // Adjust padding as needed
          child: Image.asset(
            'assets/logo.png', // <<-- REPLACE WITH YOUR CUREAI LOGO PATH
            // You might need to adjust width/height or fit for your logo
            // width: 30,
            // height: 30,
            // fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.insights, size: 30), // Fallback icon
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Creates the notch for the FAB
        notchMargin: 8.0, // Margin around the FAB notch
        color: AppColors.white,
        child: SizedBox(
          height: 60, // Standard BottomNavigationBar height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0),
              _buildBottomNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat', index: 1),
              const SizedBox(width: 40), // The space for the FAB
              _buildBottomNavItem(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services, label: 'Doctors', index: 2),
              _buildBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 4), // map_screen removed
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build individual BottomNavigationBar items
  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(20), // For splash effect
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primary : AppColors.gray, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.gray, fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    // This is your original Home screen content.
    // I'm wrapping your previous SingleChildScrollView logic here.
    return (_nickname == null && _auth.currentUser != null)
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await _fetchUserDetails();
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 60.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                const CarouselWidget(),
                const SizedBox(height: 24),
                _buildAppointmentsSection(
                  title: 'Upcoming Appointments',
                  icon: Icons.event_available_outlined,
                  query: _firestore
                      .collection('appointments')
                      .where('patientId', isEqualTo: _auth.currentUser?.uid)
                      .where('date', isGreaterThanOrEqualTo: Timestamp.now())
                      .orderBy('date')
                      .limit(5)
                      .snapshots(),
                  isUpcoming: true,
                ),
                const SizedBox(height: 24),
                _buildAppointmentsSection(
                  title: 'Previous Appointments',
                  icon: Icons.history_outlined,
                  query: _firestore
                      .collection('appointments')
                      .where('patientId', isEqualTo: _auth.currentUser?.uid)
                      .where('date', isLessThan: Timestamp.now())
                      .orderBy('date', descending: true)
                      .limit(5)
                      .snapshots(),
                  isUpcoming: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
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
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19, // Slightly adjusted
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              if (!isUpcoming && title == 'Previous Appointments') // "View All" for previous appointments
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to a full list of previous appointments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Navigate to all previous appointments (Not Implemented)")),
                    );
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: query,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity, // Ensure it takes full width
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), // Increased padding
                  decoration: BoxDecoration(
                      color: AppColors.light, // Slightly more subtle
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray.withOpacity(0.3))
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        isUpcoming ? Icons.event_note_outlined : Icons.history_toggle_off_outlined,
                        color: AppColors.gray,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isUpcoming ? 'No upcoming appointments' : 'No previous appointments',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.dark, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      if (isUpcoming) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DoctorListingScreen()),
                            ).then((_){ if(mounted) setState(() => _currentIndex = 0);});
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Book Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              snapshot.data!.docs.forEach((doc) {
                _checkAndUpdateAppointmentStatus(doc); // Check and update if needed
              });

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return _buildAppointmentCard(data, doc.id, isUpcoming);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String appointmentId, bool isUpcoming) {
    DateTime appointmentDate = (data['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('EEE, MMM d, yyyy').format(appointmentDate);
    String formattedTime = _formatTimeSlotDisplay(data['timeSlot'] as String?);
    String doctorName = data['doctorName'] as String? ?? 'Dr. Unknown';
    String specialty = data['specialty'] as String? ?? 'Consultation';
    String status = data['status'] as String? ?? (isUpcoming ? 'Scheduled' : 'Completed');
    String doctorId = data['doctorId'] as String? ?? '';

    Color statusColor = AppColors.success;
    IconData statusIcon = Icons.check_circle_outline;

    if (status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'rescheduled') {
      statusColor = AppColors.primary;
      statusIcon = Icons.alarm_on_outlined;
    } else if (status.toLowerCase() == 'cancelled') {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_outlined;
    }

    Widget cardContent = Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell( // Makes the card clickable
        borderRadius: BorderRadius.circular(15.0),
        onTap: () async {
          if (doctorId.isNotEmpty) {
            // Fetch full doctor data to pass to DoctorDetailsScreen
            // This ensures DoctorDetailsScreen has all necessary info
            try {
              DocumentSnapshot doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
              if (doctorDoc.exists) {
                Map<String, dynamic> doctorData = doctorDoc.data() as Map<String, dynamic>;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDetailsScreen(
                      doctorId: doctorId,
                      doctorData: doctorData,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor details not found.')));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error fetching doctor details: $e')));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Doctor ID not available for this appointment.')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    radius: 25,
                    child: Icon(
                      isUpcoming ? Icons.event_note_sharp : Icons.history_edu_sharp,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: TextStyle(fontSize: 14, color: AppColors.dark.withOpacity(0.7)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.gray.withOpacity(0.2)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip(Icons.calendar_today_outlined, formattedDate, AppColors.secondary),
                  _infoChip(Icons.access_time_filled_outlined, formattedTime, AppColors.secondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isUpcoming && status.toLowerCase() != 'cancelled') {
      return Slidable(
        key: Key(appointmentId),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.7,
          children: [
            SlidableAction(
              onPressed: (_) => _rescheduleAppointment(appointmentId),
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              icon: Icons.edit_calendar_outlined,
              label: 'Reschedule',
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
            ),
            SlidableAction(
              onPressed: (_) => _deleteAppointment(appointmentId),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_sweep_outlined,
              label: 'Cancel',
              borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
            ),
          ],
        ),
        child: cardContent,
      );
    }
    return cardContent;
  }

  Future<void> _checkAndUpdateAppointmentStatus(DocumentSnapshot appointmentDoc) async {
    Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;
    String currentStatus = data['status'];
    Timestamp? currentEndTimeStamp = data['currentEndTime'] as Timestamp?; // Using the new field

    if (currentStatus == 'scheduled' || currentStatus == 'rescheduled') {
      if (currentEndTimeStamp != null) {
        DateTime currentEndTime = currentEndTimeStamp.toDate();
        if (DateTime.now().isAfter(currentEndTime)) {
          // Determine if it was 'Completed' or 'Missed'
          // This requires more info (e.g., if a call happened, or if doctor/patient marked presence)
          // For a simple client-side update, we might default to 'Completed' or 'Past'
          // A more robust system would involve tracking interaction.
          String newStatus = 'Completed'; // Default to Completed
          // if (call was not made or no interaction) newStatus = 'NotAttended'; (needs more logic)

          try {
            await FirebaseFirestore.instance
                .collection('appointments')
                .doc(appointmentDoc.id)
                .update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
            debugPrint("Appointment ${appointmentDoc.id} status updated to $newStatus by client.");
          } catch (e) {
            debugPrint("Failed to update appointment status for ${appointmentDoc.id}: $e");
          }
        }
      }
    }
  }

  Widget _infoChip(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: AppColors.dark.withOpacity(0.85), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Add this helper to fetch doctor availability for rescheduling
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

  // Add this helper to check availability for the reschedule calendar
  bool _isDoctorAvailableOnDayForReschedule(DateTime day, Map<String, dynamic>? availability) {
    if (availability == null) return false;
    final String dayOfWeek = DateFormat('EEEE').format(day); // e.g., "Monday"
    if (availability.containsKey(dayOfWeek)) {
      final dayRanges = availability[dayOfWeek] as List<dynamic>?;
      return dayRanges != null && dayRanges.isNotEmpty;
    }
    return false;
  }

}

extension DateOnlyCompare on DateTime {
  bool isSameDateAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}