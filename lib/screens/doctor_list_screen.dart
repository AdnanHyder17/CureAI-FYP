// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import 'doctor_detail.page.dart';

// Doctor Listing Screen
class DoctorListingScreen extends StatefulWidget {
  const DoctorListingScreen({super.key});

  @override
  _DoctorListingScreenState createState() => _DoctorListingScreenState();
}

class _DoctorListingScreenState extends State<DoctorListingScreen> {
  String _selectedCategory = 'All';
  bool _filterOnlineOnly = false;
  String _sortBy = 'rating';
  String _searchQuery = '';

  // List of medical specialties categories
  final List<CategoryItem> _categories = [
    CategoryItem('All', Icons.medical_services, AppColors.primary),
    CategoryItem('Cardiology', Icons.favorite, Colors.red),
    CategoryItem('Ophthalmology', Icons.remove_red_eye, Colors.amber),
    CategoryItem('Orthopedics', Icons.accessibility_new, Colors.green),
    CategoryItem('Neurology', Icons.psychology, Colors.purple),
    CategoryItem('Dermatology', Icons.face, Colors.orange),
    CategoryItem('Pediatrics', Icons.child_care, Colors.blue),
    CategoryItem('Gynecology', Icons.pregnant_woman, Colors.pink),
    CategoryItem('Psychiatry', Icons.mood, Colors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Doctors', style: TextStyle(fontSize: 25,fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildCategoryList(),
          _buildFilterChips(),
          Expanded(
            child: _buildDoctorGrid(),
          ),
        ],
      ),
    );
  }

  // Search box and header section
  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Specialist',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value; // Update the search query
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name or specialty',
              prefixIcon: Icon(Icons.search, color: AppColors.gray),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal scrollable category list
  Widget _buildCategoryList() {
    return Container(
      height: 110,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.name;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.name;
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? category.color.withOpacity(0.15) : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? category.color : AppColors.gray.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected ? category.color : AppColors.light,
                    radius: 22,
                    child: Icon(
                      category.icon,
                      color: isSelected ? AppColors.white : category.color,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    category.name == 'All' ? 'All Docs' : category.name.split(' ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? category.color : AppColors.dark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align left and right
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              "Results",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
    );
  }


  // Grid of doctor cards
  Widget _buildDoctorGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildDoctorsQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading doctors. Please try again.',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.gray),
                SizedBox(height: 16),
                Text(
                  'No doctors found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search query',
                  style: TextStyle(color: AppColors.gray),
                ),
              ],
            ),
          );
        }

        List<DocumentSnapshot> doctors = snapshot.data!.docs;

        // Sort results based on selected criteria
        if (_sortBy == 'rating') {
          doctors.sort((a, b) {
            final double ratingA = (a.data() as Map)['rating'] ?? 0.0;
            final double ratingB = (b.data() as Map)['rating'] ?? 0.0;
            return ratingB.compareTo(ratingA);
          });
        } else if (_sortBy == 'experience') {

          doctors.sort((a, b) {
            final Map<String, dynamic>? dataA = a.data() as Map<String, dynamic>?;
            final Map<String, dynamic>? dataB = b.data() as Map<String, dynamic>?;

            final int expA = (dataA?['yearsOfExperience'] ?? 0.0).toInt();
            final int expB = (dataB?['yearsOfExperience'] ?? 0.0).toInt();

            return expB.compareTo(expA);
          });
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctorData = doctors[index].data() as Map<String, dynamic>;
            final doctorId = doctors[index].id;

            return DoctorCard(
              doctorId: doctorId,
              doctorData: doctorData,
              onTap: () => _navigateToDoctorDetails(doctorId, doctorData),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildDoctorsQuery() {
    Query query = FirebaseFirestore.instance.collection('doctors');

    // Apply base filters (category and online status)
    if (_selectedCategory != 'All') {
      query = query.where('specialty', isEqualTo: _selectedCategory);
    }

    if (_filterOnlineOnly) {
      query = query.where('status', isEqualTo: 'online');
    }

    // If there's a search query, handle it
    if (_searchQuery.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: _searchQuery)
          .where('nickname', isLessThanOrEqualTo: '${_searchQuery}\uf8ff')
          .snapshots()
          .asyncMap((userSnapshot) async {
        // Extract user IDs (limit to 10 to avoid Firestore's whereIn limit)
        List<String> doctorIds = userSnapshot.docs
            .map((doc) => doc.id)
            .take(10)
            .toList();

        if (doctorIds.isEmpty) {
          // Return an empty QuerySnapshot by querying an invalid document ID
          return await FirebaseFirestore.instance
              .collection('doctors')
              .where(FieldPath.documentId, isEqualTo: 'invalid-id')
              .get();
        }

        // Build doctors query with search results AND existing filters
        Query doctorsQuery = FirebaseFirestore.instance
            .collection('doctors')
            .where(FieldPath.documentId, whereIn: doctorIds);

        // Apply category filter again (if needed)
        if (_selectedCategory != 'All') {
          doctorsQuery = doctorsQuery.where('specialty', isEqualTo: _selectedCategory);
        }

        // Apply online filter again (if needed)
        if (_filterOnlineOnly) {
          doctorsQuery = doctorsQuery.where('status', isEqualTo: 'online');
        }

        return await doctorsQuery.get();
      });
    }

    // If no search query, return base query
    return query.snapshots();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Sort by',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Top Rated'),
                          value: 'rating',
                          groupValue: _sortBy,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Experience'),
                          value: 'experience',
                          groupValue: _sortBy,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Availability',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  SwitchListTile(
                    title: Text('Show online doctors only'),
                    value: _filterOnlineOnly,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _filterOnlineOnly = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _sortBy = _sortBy;
                          _filterOnlineOnly = _filterOnlineOnly;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Apply Filters'),
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

  void _navigateToDoctorDetails(String doctorId, Map<String, dynamic> doctorData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(
          doctorId: doctorId,
          doctorData: doctorData,
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  final VoidCallback onTap;

  const DoctorCard({super.key,
    required this.doctorId,
    required this.doctorData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double rating = (doctorData['rating'] ?? 0).toDouble();
    final int reviews = (doctorData['totalReviews'] ?? 0) as int;
    final String specialty = doctorData['specialty'] ?? 'General Practitioner';
    final int experience = (doctorData['yearsOfExperience'] ?? 0.0).toInt();
    final int fee = (doctorData['consultationFee'] ?? 0.0).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor image with online status indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: AppColors.light,
                    child: doctorData['profileImageUrl'] != null
                        ? CachedNetworkImage(
                      imageUrl: doctorData['profileImageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                    )
                        : _buildAvatarPlaceholder(),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor name placeholder from users collection
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          '...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        );
                      }

                      String nickname = 'Dr.';
                      if (snapshot.hasData && snapshot.data != null) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        if (userData != null && userData.containsKey('nickname')) {
                          nickname = 'Dr. ${userData['nickname']}';
                        }
                      }

                      return Text(
                        nickname,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),

                  SizedBox(height: 4),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        '($reviews)',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: AppColors.gray,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$experience yr${experience != 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray,
                            ),
                          ),
                        ]
                      ),
                      Text(
                        '${fee}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        size: 48,
        color: AppColors.gray,
      ),
    );
  }
}