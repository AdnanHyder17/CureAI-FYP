// lib/screens/doctor_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:p1/theme.dart';
import 'package:p1/screens/doctor_detail.page.dart';
import 'package:p1/widgets/loading_indicator.dart';
import 'package:p1/widgets/custom_textfield.dart';

// Model for category items
class CategoryItem {
  final String name; // Display name for the chip
  final IconData icon;
  final Color color;
  final String? firestoreValue; // Actual value to use in Firestore 'specialty' field query

  CategoryItem(this.name, this.icon, this.color, {this.firestoreValue});
}

class DoctorListingScreen extends StatefulWidget {
  const DoctorListingScreen({super.key});

  @override
  State<DoctorListingScreen> createState() => _DoctorListingScreenState();
}

class _DoctorListingScreenState extends State<DoctorListingScreen> {
  String _selectedCategoryFirestoreValue = 'All'; // Default to 'All', uses firestoreValue
  bool _filterOnlineOnly = false;
  String _sortBy = 'rating'; // Default sort: 'rating', 'experience'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Current search text

  // List of medical specialties categories
  final List<CategoryItem> _categories = [
    CategoryItem('All', Icons.medical_services_rounded, AppColors.primary, firestoreValue: 'All'),
    CategoryItem('Cardiology', Icons.favorite_rounded, Colors.red.shade400, firestoreValue: 'Cardiology'),
    CategoryItem('Dermatology', Icons.spa_rounded, Colors.orange.shade400, firestoreValue: 'Dermatology'),
    CategoryItem('Neurology', Icons.psychology_rounded, Colors.purple.shade400, firestoreValue: 'Neurology'),
    CategoryItem('Pediatrics', Icons.child_care_rounded, Colors.blue.shade400, firestoreValue: 'Pediatrics'),
    CategoryItem('Orthopedics', Icons.accessibility_new_rounded, Colors.green.shade400, firestoreValue: 'Orthopedics'),
    CategoryItem('Ophthalmology', Icons.visibility_rounded, Colors.teal.shade400, firestoreValue: 'Ophthalmology'),
    CategoryItem('Gynecology', Icons.pregnant_woman_rounded, Colors.pink.shade300, firestoreValue: 'Obstetrics & Gynecology'), // Ensure this matches Firestore data
    CategoryItem('Psychiatry', Icons.self_improvement_rounded, Colors.indigo.shade400, firestoreValue: 'Psychiatry'),
  ];

  @override
  void initState() {
    super.initState();
    // Listener to update search query state as user types
    _searchController.addListener(() {
      if (mounted) {
        // Using a simple setState. For heavy typing, consider debouncing.
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the Firestore query based on current filters and sort options.
  Stream<QuerySnapshot> _buildDoctorsQuery() {
    Query query = FirebaseFirestore.instance.collection('doctors');
    String searchQueryLower = _searchQuery.toLowerCase();

    // Apply equality filters first (category, online status)
    if (_selectedCategoryFirestoreValue != 'All') {
      query = query.where('specialty', isEqualTo: _selectedCategoryFirestoreValue);
    }
    if (_filterOnlineOnly) {
      query = query.where('status', isEqualTo: 'online');
    }

    // Apply search query filter (range filter on 'nickname_lowercase')
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('nickname_lowercase', isGreaterThanOrEqualTo: searchQueryLower)
          .where('nickname_lowercase', isLessThanOrEqualTo: '$searchQueryLower\uf8ff');

      // ** Firestore Query Constraint **
      // If a range filter (like for search) is used,
      // the FIRST orderBy clause MUST be on the same field.
      query = query.orderBy('nickname_lowercase', descending: false);

      // Apply secondary sorting if selected (might require composite indexes)
      if (_sortBy == 'rating') {
        query = query.orderBy('rating', descending: true);
      } else if (_sortBy == 'experience') {
        query = query.orderBy('yearsOfExperience', descending: true);
      }
      // If no secondary sort is chosen, it's already sorted by nickname_lowercase.

    } else {
      // No search query, so we can freely order by the selected sort field first.
      if (_sortBy == 'rating') {
        query = query.orderBy('rating', descending: true);
      } else if (_sortBy == 'experience') {
        query = query.orderBy('yearsOfExperience', descending: true);
      }
      // Add a default secondary sort for consistency when not searching.
      // This is fine as long as the primary sort field is not the same as a range filter field (which it isn't here).
      query = query.orderBy('nickname_lowercase', descending: false);
    }
    return query.snapshots();
  }


  /// Shows a modal bottom sheet for filtering and sorting options.
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true, // Important for taller content
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage state locally within the bottom sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  top: 20.0, left: 20.0, right: 20.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.0 // Adjust for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center( // Drag handle visual cue
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: AppColors.gray.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Sort & Filter', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 20),

                  Text('Sort by:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  RadioListTile<String>(
                    title: const Text('Top Rated'), value: 'rating', groupValue: _sortBy, activeColor: AppColors.primary,
                    onChanged: (value) => setModalState(() => _sortBy = value!),
                    contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                  ),
                  RadioListTile<String>(
                    title: const Text('Most Experience'), value: 'experience', groupValue: _sortBy, activeColor: AppColors.primary,
                    onChanged: (value) => setModalState(() => _sortBy = value!),
                    contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 20),

                  Text('Availability:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  SwitchListTile(
                    title: const Text('Show online doctors only'), value: _filterOnlineOnly, activeColor: AppColors.primary,
                    onChanged: (value) => setModalState(() => _filterOnlineOnly = value),
                    contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: () {
                      // Apply the filters selected in the modal to the main screen's state
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Doctor'),
        // backgroundColor is inherited from main.dart theme
      ),
      backgroundColor: AppColors.light,
      body: Column(
        children: [
          _buildSearchAndCategoryHeader(), // Search bar and category chips
          _buildFilterInfoBar(),           // Displays current filter and sort button
          Expanded(child: _buildDoctorGrid()), // Grid of doctor cards
        ],
      ),
    );
  }

  Widget _buildSearchAndCategoryHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12), // Reduced bottom padding
      decoration: BoxDecoration(
        color: AppColors.primary, // Or AppColors.white if you prefer search bar on light bg
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), // Optional rounded bottom
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: CustomTextField(
              controller: _searchController,
              labelText: 'Search by Doctor\'s Name',
              hintText: 'e.g., Dr. Smith',
              prefixIcon: Icons.search_rounded,
              isDense: true,
              onChanged: (query) {
                // The listener on _searchController handles setState
              },
              validator: null, // No validation needed for search input
            ),
          ),
          SizedBox(
            height: 60, // Height for category chips
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryFirestoreValue == category.firestoreValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategoryFirestoreValue = category.firestoreValue!);
                      }
                    },
                    avatar: category.icon != null ? Icon(category.icon, size: 18, color: isSelected ? AppColors.white : category.color) : null,
                    selectedColor: category.color, // Use category color when selected
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.dark.withOpacity(0.8), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? category.color : AppColors.gray.withOpacity(0.4))),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: isSelected ? 1 : 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInfoBar() {
    // Find the display name of the selected category
    final selectedCategoryDisplayName = _categories.firstWhere(
            (cat) => cat.firestoreValue == _selectedCategoryFirestoreValue,
        orElse: () => _categories.first // Default to 'All' if not found
    ).name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Allow text to take available space and ellipsis if too long
            child: Text(
              "Showing: $selectedCategoryDisplayName",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark.withOpacity(0.8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.filter_list, size: 20),
            label: const Text('Filters'),
            onPressed: _showFilterBottomSheet,
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildDoctorsQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator(size: 40));
        }
        if (snapshot.hasError) {
          // THIS IS WHERE THE ERROR IS CAUGHT AND DISPLAYED
          debugPrint("Error fetching doctors (DoctorListingScreen): ${snapshot.error}");
          debugPrint("Query parameters: Search='$_searchQuery', Category='$_selectedCategoryFirestoreValue', OnlineOnly='$_filterOnlineOnly', SortBy='$_sortBy'");
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 50),
                    const SizedBox(height: 10),
                    const Text('Error loading doctors.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Please try again. If the issue persists, check your internet connection or contact support.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.dark.withOpacity(0.7))),
                    const SizedBox(height: 10),
                    Text("Details: ${snapshot.error.toString()}", style: TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center,),
                  ],
                ),
              )
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(); // Shows a user-friendly "no doctors found" message
        }

        List<DocumentSnapshot> doctors = snapshot.data!.docs;
        // Note: Client-side sorting can be added here if Firestore's sorting limitations are hit.
        // For example, if sorting by 'rating' AND searching by 'nickname_lowercase'
        // doesn't work well due to Firestore index constraints, you might sort 'doctors' list here.

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Adjust top padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Standard 2 columns for mobile
            childAspectRatio: 0.72, // Aspect ratio for cards
            crossAxisSpacing: 12, // Spacing between cards horizontally
            mainAxisSpacing: 12,  // Spacing between cards vertically
          ),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctorData = doctors[index].data() as Map<String, dynamic>;
            final doctorId = doctors[index].id;
            return DoctorCard(
              doctorId: doctorId,
              doctorData: doctorData,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorDetailsScreen(doctorId: doctorId, doctorData: doctorData)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 80, color: AppColors.gray.withOpacity(0.6)),
            const SizedBox(height: 24),
            Text(
              'No Doctors Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No doctors match your search for "$_searchQuery". Try different keywords or broaden your filters.'
                  : 'No doctors match the current criteria. Try adjusting your filters or selecting a different category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dark.withOpacity(0.7), fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Doctor Card Widget (Reusable) ---
class DoctorCard extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctorId,
    required this.doctorData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = doctorData['nickname'] ?? 'Dr. Unknown';
    final String specialty = doctorData['specialty'] ?? 'Specialist';
    final String? imageUrl = doctorData['profileImageUrl'] as String?;
    final double rating = (doctorData['rating'] ?? 0.0).toDouble();
    final int experience = (doctorData['yearsOfExperience'] ?? 0).toInt();
    final bool isOnline = doctorData['status'] == 'online';
    final String fee = (doctorData['consultationFee']?.toStringAsFixed(0) ?? 'N/A');


    return Card(
      elevation: 2.0, // Softer shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6, // Image takes more space
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'doctor_image_$doctorId', // Unique tag for Hero animation
                    child: CachedNetworkImage(
                      imageUrl: imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.light.withOpacity(0.5), child: const Center(child: LoadingIndicator(size: 25, color: AppColors.primary))),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.light,
                        child: Icon(Icons.person_rounded, size: 70, color: AppColors.gray.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Online', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5, // Details part
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 16),
                              const SizedBox(width: 3),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.dark)),
                            ]),
                        Text('PKR $fee', style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$experience+ yrs exp', style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.6))),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
