// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p1/theme.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  String _selectedTab = 'About';
  String _selectedDay = '';
  String _nickname = 'Doctor';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOnline ? AppColors.success : AppColors.gray,
                      ),
                    ),
                  ],
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
    final int reviews = widget.doctorData['totalReviews'] ?? 0;
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
                      'per visit',
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
                icon: Icons.star,
                iconColor: AppColors.warning,
                value: '$rating',
                label: '$reviews Reviews',
              ),
              _buildInfoItem(
                icon: Icons.work_history,
                iconColor: AppColors.secondary,
                value: '${widget.doctorData['yearsOfExperience'] ?? 0}+',
                label: 'Experience',
              ),
              _buildInfoItem(
                icon: Icons.people,
                iconColor: AppColors.primary,
                value: '${(reviews * 2.5).floor()}+',
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

  // Action buttons for message, video call and share
  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.message,
              label: 'Message',
              color: AppColors.primary,
              onTap: () {
                // Implement message functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message feature coming soon')),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.videocam,
              label: 'Video Call',
              color: AppColors.secondary,
              onTap: () {
                // Implement video call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Video call feature coming soon')),
                );

              },
            ),
          ),
          SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            color: AppColors.gray,
            isWide: false,
            onTap: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Action button widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isWide = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  // Tab buttons for About, Experience, Reviews
  Widget _buildTabButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTabButton('About'),
          _buildTabButton('Experience'),
          _buildTabButton('Reviews'),
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
      case 'Reviews':
        return _buildReviewsContent();
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
    Map<String, dynamic> availability = widget.doctorData['availability'] ?? {};
    List<String> weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) {
            final shortDay = day.substring(0, 3);
            final bool isAvailable = availability.containsKey(day) &&
                availability[day] is List &&
                (availability[day] as List).isNotEmpty;
            final bool isSelected = _selectedDay == day;

            return GestureDetector(
              onTap: isAvailable ? () {
                setState(() {
                  _selectedDay = isSelected ? '' : day;
                });
              } : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isAvailable ? AppColors.light : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAvailable
                        ? (isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.3))
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    shortDay,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : (isAvailable ? AppColors.dark : AppColors.gray),
                      fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedDay.isNotEmpty &&
            availability.containsKey(_selectedDay) &&
            availability[_selectedDay] is List)
          Container(
            margin: EdgeInsets.only(top: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedDay Availability',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  // runSpacing: 8,
                  children: (availability[_selectedDay] as List).map<Widget>((slot) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        _formatTimeSlot(slot.toString()),
                        style: TextStyle(
                          color: AppColors.dark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }


  // Format time slot from Firebase
  String _formatTimeSlot(String timeCode) {
    List<String> parts = timeCode.split(":");
    if (parts.length >= 2) {
      int hour = int.tryParse(parts[0]) ?? 0;
      int period = hour >= 12 ? 1 : 0; // 0 for AM, 1 for PM
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour:00 ${period == 0 ? 'AM' : 'PM'}';
    }
    return timeCode;
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

  // Reviews tab content
  Widget _buildReviewsContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewSummary(),
          SizedBox(height: 24),
          Text(
            'Patient Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          widget.doctorData['totalReviews'] == 0 || widget.doctorData['totalReviews'] == null
              ? _buildNoReviewsMessage()
              : _buildMockReviews(),
        ],
      ),
    );
  }

  // Review summary with rating bars
  Widget _buildReviewSummary() {
    final double rating = (widget.doctorData['rating'] ?? 0).toDouble();
    final int reviews = widget.doctorData['totalReviews'] ?? 0;

    // Mock distribution for rating bars
    final List<double> distribution = [0.7, 0.15, 0.1, 0.03, 0.02];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 4),
              RatingBar.builder(
                initialRating: rating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 18,
                ignoreGestures: true,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: AppColors.warning,
                ),
                onRatingUpdate: (_) {},
              ),
              SizedBox(height: 4),
              Text(
                'Based on $reviews reviews',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final int star = 5 - index;
                final double percentage = reviews > 0 ? distribution[index] : 0;

                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 4),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: AppColors.gray.withOpacity(0.2),
                            color: AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Message when there are no reviews
  Widget _buildNoReviewsMessage() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 24),
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: AppColors.gray.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to leave a review after your appointment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  // Mock reviews for demonstration
  Widget _buildMockReviews() {
    // Creating mock reviews for demonstration
    List<Map<String, dynamic>> mockReviews = [
      {
        'name': 'Sarah Johnson',
        'date': '2 weeks ago',
        'rating': 5.0,
        'content': 'Excellent doctor! Very attentive and explained everything clearly. Would highly recommend.',
      },
      {
        'name': 'Michael Brown',
        'date': '1 month ago',
        'rating': 4.5,
        'content': 'Great experience. The doctor was knowledgeable and took time to address all my concerns.',
      },
    ];

    return Column(
      children: mockReviews.map((review) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.light,
                    child: Text(
                      review['name'].toString().substring(0, 1),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          review['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RatingBar.builder(
                    initialRating: review['rating'],
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 14,
                    ignoreGestures: true,
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: AppColors.warning,
                    ),
                    onRatingUpdate: (_) {},
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                review['content'],
                style: TextStyle(
                  color: AppColors.dark.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
          onPressed: () => _showAppointmentBookingDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book Appointment',
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
    DateTime selectedDate = DateTime.now();
    String? selectedTimeSlot;
    List<String> availableTimeSlots = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Center(
                      child: Text(
                        'Book an Appointment',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Selection
                          const Text(
                            'Select Date',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CalendarDatePicker(
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                              onDateChanged: (date) async {
                                selectedDate = date;
                                selectedTimeSlot = null;

                                // Get day of week
                                String dayOfWeek = _getDayOfWeek(date.weekday);

                                // Fetch available time slots for this day from doctor's data
                                await _fetchAvailableTimeSlots(dayOfWeek).then((slots) {
                                  setState(() {
                                    availableTimeSlots = slots;
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Time Slot Selection
                          const Text(
                            'Select Time Slot',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          availableTimeSlots.isEmpty
                              ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'No available slots for selected date',
                                style: TextStyle(color: AppColors.gray),
                              ),
                            ),
                          )
                              : Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.5,
                              ),
                              itemCount: availableTimeSlots.length,
                              itemBuilder: (context, index) {
                                final timeSlot = availableTimeSlots[index];
                                final bool isSelected = timeSlot == selectedTimeSlot;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedTimeSlot = timeSlot;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.secondary : AppColors.light,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.light,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _aformatTimeSlot(timeSlot),
                                        style: TextStyle(
                                          color: isSelected ? AppColors.onSecondary : AppColors.dark,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Confirmation Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: selectedTimeSlot == null
                          ? null
                          : () => _confirmAppointment(selectedDate, selectedTimeSlot!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.gray,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    final parts = rawTimeSlot.split(':');
    if (parts.length != 2) return rawTimeSlot;

    int hour = int.tryParse(parts[0]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$hour $period';
  }

// Fetch available time slots for a given day
  Future<List<String>> _fetchAvailableTimeSlots(String dayOfWeek) async {
    try {
      // Check if the doctor has availability for this day
      if (widget.doctorData['availability'] != null &&
          widget.doctorData['availability'][dayOfWeek] != null) {
        // Return the time slots for this day
        return List<String>.from(widget.doctorData['availability'][dayOfWeek]);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching time slots: $e');
      return [];
    }
  }

// Show confirmation dialog and save appointment
  void _confirmAppointment(DateTime selectedDate, String timeSlot) async {
    // Get current user ID
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String? patientId = auth.currentUser?.uid;

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
            Text('Fee: \$${widget.doctorData['consultationFee'] ?? 0}',
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

// Separate method to handle the actual booking process
  Future<void> _bookAppointment(DateTime selectedDate, String timeSlot, String patientId) async {
    bool isLoading = true;
    bool isError = false;
    String errorMessage = '';

    // Show loading dialog with the ability to dismiss it
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
      // Create appointment data
      final Map<String, dynamic> appointmentData = {
        'patientId': patientId,
        'doctorId': widget.doctorId,
        'date': Timestamp.fromDate(selectedDate),
        'timeSlot': timeSlot,
        'status': 'scheduled',
        'consultationFee': widget.doctorData['consultationFee'] ?? 0,
        'createdAt': Timestamp.now(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      isLoading = false;
    } catch (e) {
      isLoading = false;
      isError = true;
      errorMessage = e.toString();
      debugPrint('Error booking appointment: $e');
    }

    // Make sure to close the loading dialog in all cases
    if (isLoading == false) {
      // Safety check to make sure dialog is still showing before trying to close it
      Navigator.of(dialogContext, rootNavigator: true).pop();

      if (isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $errorMessage'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        Navigator.pop(context); // Close appointment booking dialog
        _showSuccessDialog();
      }
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

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem(this.name, this.icon, this.color);
}