import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'map_Screen.dart';
import 'profile_screen.dart';
import 'doctor_list_screen.dart';
import 'package:p1/theme.dart';


class _CarouselWidget extends StatefulWidget {
  const _CarouselWidget();

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<_CarouselWidget> {
  final PageController _pageController = PageController();
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
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    _setupCarouselAutoScroll();
  }

  void _setupCarouselAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_pageController.hasClients && mounted) {
        final nextPage = (_currentCarouselPage + 1) % _carouselItems.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
      if (mounted) {
        _setupCarouselAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentCarouselPage = index),
            itemCount: _carouselItems.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      stops: const [0.6, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.darken,
                    child: Image.asset(
                      _carouselItems[index]['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _carouselItems[index]['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 3.0, color: Colors.black45)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _carouselItems[index]['description'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 3.0, color: Colors.black45)],
                          ),
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
                  expansionFactor: 3,
                  spacing: 5,
                  activeDotColor: AppColors.secondary,
                  dotColor: AppColors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? nickname;
  String? role;
  int _currentIndex = 0;
  bool _showProfileMenu = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Carousel Controller with auto-scroll
  final PageController _pageController = PageController();
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
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _updateAppointmentsWithDoctorInfo();
    _setupCarouselAutoScroll();

    // Initialize animation controller
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
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupCarouselAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_pageController.hasClients && mounted) {
        final nextPage = (_currentCarouselPage + 1) % _carouselItems.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
      if (mounted) {
        _setupCarouselAutoScroll();
      }
    });
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            nickname = userDoc['nickname'];
            role = userDoc['role'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
  }

  Future<void> _updateAppointmentsWithDoctorInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot appointmentsSnapshot = await _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: user.uid)
            .get();

        for (var doc in appointmentsSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String doctorId = data['doctorId'];

          if ((data['doctorName'] == null || data['specialty'] == null)) {
            // Get doctor specialty from doctors collection
            DocumentSnapshot doctorDoc = await _firestore
                .collection('doctors')
                .doc(doctorId)
                .get();

            // Get doctor name from users collection
            DocumentSnapshot userDoc = await _firestore
                .collection('users')
                .doc(doctorId)
                .get();

            Map<String, dynamic> updateData = {};

            if (doctorDoc.exists) {
              Map<String, dynamic> doctorData = doctorDoc.data() as Map<String, dynamic>;
              updateData['specialty'] = doctorData['specialty'];
            }

            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              updateData['doctorName'] = userData['nickname'];
            }

            if (updateData.isNotEmpty) {
              await _firestore.collection('appointments').doc(doc.id).update(updateData);
            }
          }
        }
      }
    } catch (e) {
      print('Error updating appointments with doctor info: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: AppColors.gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Cancellation'),
          content: const Text(
            'Are you sure you want to cancel this appointment?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: TextStyle(color: AppColors.gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
            SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showProfileMenu) {
          setState(() {
            _showProfileMenu = false;
          });
        }
      },
      child: Scaffold(
        appBar:
        AppBar(
          title: Text(
            nickname != null ? 'Welcome, $nickname!' : 'Welcome!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'logout') _confirmLogout();
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  radius: 20,
                  child: Text(
                    nickname?.isNotEmpty == true
                        ? nickname![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),


        body:
            nickname == null || role == null
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : AnimationLimiter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await _fetchUserDetails();
                        setState(() {});
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 375),
                            childAnimationBuilder:
                                (widget) => SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                            children: [
                              // Enhanced Carousel with Overlay Text
                              const _CarouselWidget(),
                              const SizedBox(height: 20),

                              // Upcoming Appointments Container
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upcoming Appointments',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Upcoming appointments
                                    StreamBuilder<QuerySnapshot>(
                                      stream:
                                          _firestore
                                              .collection('appointments')
                                              .where(
                                                'patientId',
                                                isEqualTo: _auth.currentUser?.uid,
                                              )
                                              .where(
                                                'date',
                                                isGreaterThanOrEqualTo:
                                                    Timestamp.now(),
                                          )
                                              .orderBy('date')
                                              .limit(5)
                                              .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: SizedBox(
                                              height: 100,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.primary),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: AppColors.light,
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.event_busy,
                                                  color: AppColors.gray,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No upcoming appointments',
                                                  style: TextStyle(
                                                    color: AppColors.dark,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                DoctorListingScreen(),
                                                      ),
                                                    );
                                                  },
                                                  icon: Icon(Icons.add),
                                                  label: Text(
                                                    'Book an Appointment',
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        AppColors.white,
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Column(
                                          children:
                                              snapshot.data!.docs.map((doc) {
                                                Map<String, dynamic> data =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                DateTime appointmentDate =
                                                    (data['date'] as Timestamp)
                                                        .toDate();
                                                String formattedDate = DateFormat(
                                                  'EEE, MMM d, yyyy',
                                                ).format(appointmentDate);
                                                String formattedTime =
                                                    data['timeSlot'] != null
                                                        ? _formatTimeSlot(
                                                          data['timeSlot'],
                                                        )
                                                        : 'Time not specified';

                                                return Slidable(
                                                  key: Key(doc.id),
                                                  endActionPane: ActionPane(
                                                    motion: const ScrollMotion(),
                                                    children: [
                                                      SlidableAction(
                                                        onPressed:
                                                            (_) =>
                                                                _rescheduleAppointment(
                                                                  doc.id,
                                                                ),
                                                        backgroundColor:
                                                            AppColors.warning,
                                                        foregroundColor:
                                                            Colors.white,
                                                        icon: Icons.edit_calendar,
                                                        label: 'Reschedule',
                                                        borderRadius:
                                                            BorderRadius.horizontal(
                                                              left:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                      ),
                                                      SlidableAction(
                                                        onPressed:
                                                            (_) =>
                                                                _deleteAppointment(
                                                                  doc.id,
                                                                ),
                                                        backgroundColor:
                                                            AppColors.error,
                                                        foregroundColor:
                                                            Colors.white,
                                                        icon: Icons.cancel,
                                                        label: 'Cancel',
                                                        borderRadius:
                                                            BorderRadius.horizontal(
                                                              right:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Container(
                                                    margin: const EdgeInsets.only(
                                                      bottom: 12,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.05),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 50,
                                                                height: 50,
                                                                decoration: BoxDecoration(
                                                                  color: AppColors
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .medical_services,
                                                                  color:
                                                                      AppColors
                                                                          .primary,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Dr. ${data['doctorName'] ?? 'Unknown'}',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color:
                                                                            AppColors
                                                                                .dark,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 4,
                                                                    ),
                                                                    Text(
                                                                      data['specialty'] ??
                                                                          'Medical Appointment',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            AppColors
                                                                                .gray,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical: 6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors
                                                                      .success
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Confirmed',
                                                                  style: TextStyle(
                                                                    color:
                                                                        AppColors
                                                                            .success,
                                                                    fontSize: 12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          const Divider(
                                                            height: 1,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .calendar_month,
                                                                      color:
                                                                          AppColors
                                                                              .primary,
                                                                      size: 16,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      formattedDate,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            AppColors
                                                                                .dark,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .access_time,
                                                                      color:
                                                                          AppColors
                                                                              .primary,
                                                                      size: 16,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      formattedTime,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            AppColors
                                                                                .dark,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Text(
                                                            'Swipe left for options →',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  AppColors.gray,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Previous Appointments Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.history,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Previous Appointments',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.dark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Navigate to full appointment history
                                          },
                                          child: Text(
                                            'View All',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Previous appointments
                                    StreamBuilder<QuerySnapshot>(
                                      stream:
                                          _firestore
                                              .collection('appointments')
                                              .where(
                                                'patientId',
                                                isEqualTo: _auth.currentUser?.uid,
                                              )
                                              .where(
                                                'date',
                                                isLessThan: Timestamp.now(),
                                              )
                                              .orderBy('date', descending: true)
                                              .limit(5)
                                              .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: SizedBox(
                                              height: 100,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.primary),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: AppColors.light,
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.history_toggle_off,
                                                    color: AppColors.gray,
                                                    size: 48,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No previous appointments',
                                                    style: TextStyle(
                                                      color: AppColors.dark,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            var doc = snapshot.data!.docs[index];
                                            Map<String, dynamic> data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            DateTime appointmentDate =
                                                (data['date'] as Timestamp)
                                                    .toDate();
                                            String formattedDate = DateFormat(
                                              'MMM d, yyyy',
                                            ).format(appointmentDate);

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.light,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor:
                                                      AppColors.light,
                                                  child: Icon(
                                                    Icons.healing,
                                                    color: AppColors.dark,
                                                  ),
                                                ),
                                                title: Text(
                                                  'Dr. ${data['doctorName'] ?? 'Unknown'}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.dark,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${data['specialty'] ?? 'Consultation'} • $formattedDate',
                                                  style: TextStyle(
                                                    color: AppColors.gray,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon: Icon(
                                                    Icons.medical_information,
                                                    color: AppColors.secondary,
                                                  ),
                                                  onPressed: () {
                                                    // Show appointment details
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    20,
                                                                  ),
                                                            ),
                                                      ),
                                                      builder:
                                                          (context) =>
                                                              _buildAppointmentDetailsSheet(
                                                                data,
                                                              ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom padding
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });

              // Handle navigation
              if (index != 0) {
                Widget screen;
                switch (index) {
                  case 1:
                    screen = ChatScreen();
                    break;
                  case 2:
                    screen = DoctorListingScreen();
                    break;
                  case 3:
                    screen = MapScreen();
                    break;
                  case 4:
                    screen = ProfileScreen();
                    break;
                  default:
                    return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.gray,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services),
                label: 'Doctors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeSlot(String timeSlot) {
    // Convert time slots like "09:00-09:30" to more readable format
    if (timeSlot.contains('-')) {
      List<String> parts = timeSlot.split('-');
      return '${_format12Hour(parts[0])} - ${_format12Hour(parts[1])}';
    }
    return timeSlot;
  }

  String _format12Hour(String time) {
    try {
      final timeFormat = DateFormat('HH:mm');
      final dateTime = timeFormat.parse(time);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  Widget _buildAppointmentDetailsSheet(Map<String, dynamic> appointmentData) {
    DateTime appointmentDate = (appointmentData['date'] as Timestamp).toDate();
    String formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(appointmentDate);
    String formattedTime =
        appointmentData['timeSlot'] != null
            ? _formatTimeSlot(appointmentData['timeSlot'])
            : 'Time not specified';

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.gray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 20),
          _detailRow(
            Icons.person,
            'Doctor',
            'Dr. ${appointmentData['doctorName'] ?? 'Unknown'}',
          ),
          _detailRow(
            Icons.medical_services,
            'Specialty',
            appointmentData['specialty'] ?? 'General',
          ),
          _detailRow(Icons.calendar_today, 'Date', formattedDate),
          _detailRow(Icons.access_time, 'Time', formattedTime),
          _detailRow(
            Icons.location_on,
            'Location',
            appointmentData['location'] ?? 'Main Clinic',
          ),
          _detailRow(
            Icons.note,
            'Notes',
            appointmentData['notes'] ?? 'No notes provided',
          ),

          SizedBox(height: 24),

          if (appointmentData['diagnosis'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                SizedBox(height: 16),
                Text(
                  'Diagnosis & Treatment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointmentData['diagnosis'],
                    style: TextStyle(fontSize: 15, color: AppColors.dark),
                  ),
                ),
              ],
            ),

          SizedBox(height: 24),

          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: AppColors.gray),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.dark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _rescheduleAppointment(String appointmentId) async {
    try {
      // First, get the current appointment data
      DocumentSnapshot appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment not found')),
        );
        return;
      }

      Map<String, dynamic> appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      String doctorId = appointmentData['doctorId'];

      // Fetch doctor availability
      DocumentSnapshot doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor information not available')),
        );
        return;
      }

      Map<String, dynamic> doctorData = doctorDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> availability = doctorData['availability'] ?? {};

      // Show date picker
      DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 30)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                onSurface: AppColors.dark,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedDate == null) return;

      // Get day of week
      String dayOfWeek = DateFormat('EEEE').format(selectedDate);

      // Check if doctor is available on selected day
      List<dynamic>? availableSlots = availability[dayOfWeek];
      if (availableSlots == null || availableSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor is not available on $dayOfWeek')),
        );
        return;
      }

      // Show time slot picker
      String? selectedTimeSlot = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Time Slot'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_formatTimeSlot(availableSlots[index])),
                    onTap: () {
                      Navigator.of(context).pop(availableSlots[index]);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedTimeSlot == null) return;

      // Update appointment in database
      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': Timestamp.fromDate(selectedDate),
        'timeSlot': selectedTimeSlot,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error rescheduling appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
