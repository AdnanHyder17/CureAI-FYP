// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:p1/theme.dart';
//
// class DoctorExploreScreen extends StatefulWidget {
//   const DoctorExploreScreen({Key? key}) : super(key: key);
//
//   @override
//   State<DoctorExploreScreen> createState() => _DoctorExploreScreenState();
// }
//
// class _DoctorExploreScreenState extends State<DoctorExploreScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedCategory = "";
//   List<String> specialties = [
//     "Cardiology",
//     "Ophthalmology",
//     "Orthopedics",
//     "Neurology",
//     "Dermatology",
//     "Pediatrics",
//     "Gynecology",
//     "Psychiatry",
//   ];
//
//   Map<String, String> categoryToSpecialty = {
//     "All": "",
//     "Heart": "Cardiology",
//     "Eyes": "Ophthalmology",
//     "Bones": "Orthopedics",
//     "Brain": "Neurology",
//     "Skin": "Dermatology",
//     "Children": "Pediatrics",
//     "Women's Health": "Gynecology",
//     "Mental Health": "Psychiatry",
//   };
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Find Doctors'),
//         elevation: 0,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeaderSection(),
//           _buildCategoriesSection(),
//           Expanded(
//             child: _buildDoctorGrid(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeaderSection() {
//     return Container(
//       color: AppColors.primary,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//       child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//       StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('doctors')
//           .where('status', isEqualTo: 'active')
//           .snapshots(),
//       builder: (context, snapshot) {
//         int doctorCount = 0;
//         if (snapshot.hasData) {
//           doctorCount = snapshot.data!.size;
//         }
//
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 16),
//           child: Text(
//             '$doctorCount Doctors Available',
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//               color: AppColors.white,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         );
//       },
//     ),
//             Container(
//               decoration: BoxDecoration(
//                 color: AppColors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.dark.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) {
//                   setState(() {});
//                 },
//                 decoration: InputDecoration(
//                   hintText: "Search by specialty...",
//                   prefixIcon: const Icon(Icons.search, color: AppColors.primary),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 ),
//               ),
//             ),
//
//           ],
//     ),
//     );
//   }
//
//   Widget _buildCategoriesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
//           child: Text(
//             'Categories',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//         ),
//         SizedBox(
//           height: 120,
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             scrollDirection: Axis.horizontal,
//             itemCount: categoryToSpecialty.length,
//             itemBuilder: (context, index) {
//               String category = categoryToSpecialty.keys.elementAt(index);
//               return _buildCategoryItem(category);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCategoryItem(String category) {
//     bool isSelected = _selectedCategory == category;
//
//     Map<String, IconData> categoryIcons = {
//       'All': Icons.medical_services,
//       'Heart': Icons.favorite,
//       'Eyes': Icons.visibility,
//       'Bones': Icons.accessibility_new,
//       'Brain': Icons.psychology,
//       'Skin': Icons.face,
//       'Children': Icons.child_care,
//       'Women\'s Health': Icons.pregnant_woman,
//       'Mental Health': Icons.sentiment_satisfied_alt,
//     };
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedCategory = isSelected ? "" : category;
//         });
//       },
//       child: Container(
//         width: 90,
//         margin: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primary : AppColors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.gray.withOpacity(0.2),
//               blurRadius: 6,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               categoryIcons[category] ?? Icons.medical_services,
//               color: isSelected ? AppColors.white : AppColors.primary,
//               size: 32,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               category,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: isSelected ? AppColors.white : AppColors.dark,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//
//   }
//
//   Widget _buildDoctorGrid() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _buildDoctorQuery(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }
//
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.search_off, size: 64, color: AppColors.gray),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No doctors found',
//                   style: Theme.of(context).textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Try adjusting your search or filters',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: AppColors.gray,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Padding(
//           padding: const EdgeInsets.all(12),
//           child: GridView.builder(
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.75,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//             ),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data() as Map<String, dynamic>;
//
//               return _buildDoctorCard(doc.id, data);
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDoctorCard(String doctorId, Map<String, dynamic> data) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DoctorDetailScreen(doctorId: doctorId),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.gray.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                   child: Container(
//                     height: 120,
//                     width: double.infinity,
//                     color: AppColors.primary.withOpacity(0.15),
//                     child: const Icon(
//                       Icons.person,
//                       size: 64,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.white,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(
//                           Icons.star,
//                           color: AppColors.warning,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${data['rating'] ?? 0.0}',
//                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   FutureBuilder<DocumentSnapshot>(
//                     future: FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(data['uid'])
//                         .get(),
//                     builder: (context, userSnapshot) {
//                       if (userSnapshot.connectionState == ConnectionState.waiting) {
//                         return Text(
//                           'Loading...',
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontSize: 16,
//                           ),
//                         );
//                       }
//                       if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
//                         return Text(
//                           'Unknown Doctor',
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontSize: 16,
//                           ),
//                         );
//                       }
//                       final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
//                       final name = userData?['nickname'] ?? 'Unknown Doctor';
//                       return Text(
//                         name,
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           fontSize: 16,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     data['specialty'] ?? 'Specialist',
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.work_outline,
//                         size: 14,
//                         color: AppColors.gray,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${data['yearsOfExperience']?.toString() ?? '0'} yrs',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppColors.gray,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Icon(
//                         Icons.currency_rupee,
//                         size: 14,
//                         color: AppColors.gray,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '₹${data['consultationFee']?.toString() ?? '0'}',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppColors.gray,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Stream<QuerySnapshot> _buildDoctorQuery() {
//     Query query = FirebaseFirestore.instance
//         .collection('doctors')
//         .where('status', isEqualTo: 'active');
//
//     if (_selectedCategory.isNotEmpty && categoryToSpecialty[_selectedCategory] != null) {
//       String specialty = categoryToSpecialty[_selectedCategory]!;
//       if (specialty.isNotEmpty) {
//         query = query.where('specialty', isEqualTo: specialty);
//       }
//     }
//
//     String searchText = _searchController.text.trim().toLowerCase();
//     if (searchText.isNotEmpty) {
//       return query.snapshots().map((snapshot) {
//         final filteredDocs = snapshot.docs.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           if (data.containsKey('specialty') && data['specialty'] != null) {
//             final specialty = data['specialty'].toString().toLowerCase();
//             return specialty.contains(searchText);
//           }
//           return false;
//         }).toList();
//
//         return _CustomQuerySnapshot(
//           docs: filteredDocs,
//           metadata: snapshot.metadata,
//           size: filteredDocs.length,
//           docChanges: [],
//         );
//       });
//     }
//
//     return query.snapshots();
//   }
// }
//
// class _CustomQuerySnapshot extends QuerySnapshot {
//   @override
//   final List<QueryDocumentSnapshot> docs;
//   @override
//   final SnapshotMetadata metadata;
//   @override
//   final int size;
//   @override
//   final List<DocumentChange> docChanges;
//
//   _CustomQuerySnapshot({
//     required this.docs,
//     required this.metadata,
//     required this.size,
//     required this.docChanges,
//   });
// }
//
// // Placeholder for the DoctorDetailScreen to make the code compile
// // class DoctorDetailScreen extends StatelessWidget {
// //   final String doctorId;
// //
// //   const DoctorDetailScreen({
// //     Key? key,
// //     required this.doctorId,
// //   }) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Doctor Profile'),
// //       ),
// //       body: const Center(
// //         child: Text('Doctor Detail Screen'),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// //Doctor Detail Screen
// class DoctorDetailScreen extends StatelessWidget {
//   final String doctorId;
//
//   const DoctorDetailScreen({
//     Key? key,
//     required this.doctorId,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Doctor Profile'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share),
//             onPressed: () {
//               // Share functionality
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('doctors')
//             .doc(doctorId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 64, color: AppColors.error),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Doctor not found',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.arrow_back),
//                     label: const Text('Go Back'),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           final data = snapshot.data!.data() as Map<String, dynamic>;
//
//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDoctorHeader(context, data),
//
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildInfoSection(context, 'About', data['bio'] ?? 'No information provided.'),
//
//                       const SizedBox(height: 24),
//
//                       _buildQualificationsSection(context, data),
//
//                       const SizedBox(height: 24),
//
//                       _buildAvailabilitySection(context, data),
//
//                       const SizedBox(height: 32),
//
//                       _buildBookingButton(context),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDoctorHeader(BuildContext context, Map<String, dynamic> data) {
//     return Container(
//       color: AppColors.primary,
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
//       child: Column(
//         children: [
//           // Doctor image and basic details
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Doctor avatar
//               Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   color: AppColors.white,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: AppColors.white, width: 3),
//                 ),
//                 child: const Center(
//                   child: Icon(Icons.person, size: 64, color: AppColors.primary),
//                 ),
//               ),
//
//               const SizedBox(width: 16),
//
//               // Doctor info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Fetch and display user data
//                     FutureBuilder<DocumentSnapshot>(
//                       future: FirebaseFirestore.instance
//                           .collection('users')
//                           .doc(data['uid'])
//                           .get(),
//                       builder: (context, userSnapshot) {
//                         if (!userSnapshot.hasData) {
//                           return const Text('Loading...',
//                               style: TextStyle(color: AppColors.white));
//                         }
//
//                         final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
//                         final name = userData?['nickname'] ?? 'Unknown Doctor';
//
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               name,
//                               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                 color: AppColors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               data['specialization'] ?? 'Specialist',
//                               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                                 color: AppColors.secondary,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 _buildStatItem(
//                                   context,
//                                   '${data['experience'] ?? 0}+',
//                                   'Years',
//                                 ),
//                                 const SizedBox(width: 16),
//                                 _buildStatItem(
//                                   context,
//                                   '${data['totalReviews'] ?? 0}',
//                                   'Reviews',
//                                 ),
//                                 const SizedBox(width: 16),
//                                 _buildStatItem(
//                                   context,
//                                   '${data['rating'] ?? 0.0}',
//                                   'Rating',
//                                   showStar: true,
//                                 ),
//                               ],
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           // Fee information
//           Container(
//             margin: const EdgeInsets.only(top: 20),
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: BoxDecoration(
//               color: AppColors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Consultation Fee',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: AppColors.white,
//                   ),
//                 ),
//                 Text(
//                   '₹${data['consultationFee'] ?? 0}',
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                     color: AppColors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem(BuildContext context, String value, String label, {bool showStar = false}) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             if (showStar)
//               const Icon(Icons.star, color: AppColors.warning, size: 18),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 color: AppColors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//             color: AppColors.white.withOpacity(0.7),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInfoSection(BuildContext context, String title, String content) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           content,
//           style: Theme.of(context).textTheme.bodyMedium,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQualificationsSection(BuildContext context, Map<String, dynamic> data) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Qualifications',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppColors.light,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             children: [
//               _buildQualificationItem(
//                 context,
//                 Icons.school,
//                 'Qualification',
//                 data['qualification'] ?? 'Not specified',
//               ),
//               const Divider(),
//               _buildQualificationItem(
//                 context,
//                 Icons.work,
//                 'Experience',
//                 '${data['experience'] ?? 0} years',
//               ),
//               const Divider(),
//               _buildQualificationItem(
//                 context,
//                 Icons.medical_services,
//                 'Specialization',
//                 data['specialization'] ?? 'General Medicine',
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQualificationItem(
//       BuildContext context,
//       IconData icon,
//       String label,
//       String value,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: AppColors.primary),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.gray,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 value,
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAvailabilitySection(BuildContext context, Map<String, dynamic> data) {
//     Map<String, dynamic> availability = data['availability'] ?? {};
//     List<String> daysOfWeek = [
//       'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
//     ];
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Availability',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         const SizedBox(height: 12),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: AppColors.gray.withOpacity(0.3)),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: daysOfWeek.length,
//             separatorBuilder: (context, index) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               String day = daysOfWeek[index];
//               List<dynamic> slots = availability[day] ?? [];
//
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Day name
//                     Text(
//                       day.substring(0, 1).toUpperCase() + day.substring(1),
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//
//                     // Slots
//                     if (slots.isEmpty)
//                       Text(
//                         'Not Available',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppColors.gray,
//                         ),
//                       )
//                     else
//                       Flexible(
//                         child: Text(
//                           _formatAvailabilitySlots(slots),
//                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             color: AppColors.primary,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.right,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _formatAvailabilitySlots(List<dynamic> slots) {
//     if (slots.isEmpty) return 'Not Available';
//
//     List<String> formattedSlots = [];
//     for (var slot in slots) {
//       if (slot is Map && slot.containsKey('startTime') && slot.containsKey('endTime')) {
//         Timestamp? startTime = slot['startTime'] as Timestamp?;
//         Timestamp? endTime = slot['endTime'] as Timestamp?;
//
//         // if (startTime != null && endTime != null) {
//         //   String formattedSlot = '${DateFormat('h:mm a').format(startTime.toDate())} - ${DateFormat('h:mm a').format(endTime.toDate())}';
//         //   formattedSlots.add(formattedSlot);
//         // }
//       }
//     }
//
//     return formattedSlots.join(', ');
//   }
//
//   Widget _buildBookingButton(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           // Navigate to booking screen
//         },
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//         child: Text(
//           'Book Appointment',
//           style: Theme.of(context).textTheme.labelLarge,
//         ),
//       ),
//     );
//   }
// }






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
            child: Text('Error: ${snapshot.error}'),
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

    if (_selectedCategory != 'All') {
      query = query.where('specialty', isEqualTo: _selectedCategory);
    }

    if (_filterOnlineOnly) {
      query = query.where('status', isEqualTo: 'online');
    }

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
    final bool isOnline = doctorData['status'] == 'online';
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.success : AppColors.gray,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 10,
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
                        ],
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

// // Doctor Details Screen
// class DoctorDetailsScreen extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> doctorData;
//
//   const DoctorDetailsScreen({super.key,
//     required this.doctorId,
//     required this.doctorData,
//   });
//
//   @override
//   _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
// }
//
// class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
//   String _selectedTab = 'About';
//   String _selectedDay = '';
//   String _nickname = 'Doctor';
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }
//
//   Future<void> _fetchUserData() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.doctorId)
//           .get();
//
//       if (userDoc.exists) {
//         final userData = userDoc.data() as Map<String, dynamic>;
//         if (userData.containsKey('nickname')) {
//           setState(() {
//             _nickname = userData['nickname'];
//           });
//         }
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isOnline = widget.doctorData['status'] == 'online';
//
//     return Scaffold(
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : CustomScrollView(
//         slivers: [
//           _buildAppBar(isOnline),
//           SliverToBoxAdapter(
//             child: Column(
//               children: [
//                 _buildDoctorInfo(),
//                 _buildActionButtons(),
//                 _buildTabButtons(),
//                 _buildTabContent(),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: _buildBookAppointmentButton(),
//     );
//   }
//
//   // Custom app bar with doctor image
//   Widget _buildAppBar(bool isOnline) {
//     return SliverAppBar(
//       expandedHeight: 200,
//       pinned: true,
//       leading: Container(
//         margin: EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: AppColors.surface.withOpacity(0.7),
//           shape: BoxShape.circle,
//         ),
//         child: IconButton(
//           icon: Icon(Icons.arrow_back),
//           color: AppColors.dark,
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       flexibleSpace: FlexibleSpaceBar(
//         background: Stack(
//           children: [
//             Container(
//               width: double.infinity,
//               height: double.infinity,
//               color: AppColors.light,
//               child: widget.doctorData['profileImageUrl'] != null
//                   ? CachedNetworkImage(
//                 imageUrl: widget.doctorData['profileImageUrl'],
//                 fit: BoxFit.cover,
//                 placeholder: (context, url) => Center(
//                   child: CircularProgressIndicator(color: AppColors.primary),
//                 ),
//                 errorWidget: (context, url, error) => _buildProfilePlaceholder(),
//               )
//                   : _buildProfilePlaceholder(),
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.transparent,
//                     Colors.black.withOpacity(0.7),
//                   ],
//                   stops: [0.6, 1.0],
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 16,
//               right: 16,
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface.withOpacity(0.8),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isOnline ? AppColors.success : AppColors.gray,
//                       ),
//                     ),
//                     SizedBox(width: 6),
//                     Text(
//                       isOnline ? 'Online' : 'Offline',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isOnline ? AppColors.success : AppColors.gray,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Doctor info section
//   Widget _buildDoctorInfo() {
//     final double rating = (widget.doctorData['rating'] ?? 0).toDouble();
//     final int reviews = widget.doctorData['totalReviews'] ?? 0;
//     final String specialty = widget.doctorData['specialty'] ?? 'Specialist';
//
//     return Padding(
//       padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Dr. $_nickname',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       specialty,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: AppColors.light,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '\$${widget.doctorData['consultationFee']/1000}k',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     Text(
//                       'per visit',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppColors.gray,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildInfoItem(
//                 icon: Icons.star,
//                 iconColor: AppColors.warning,
//                 value: '$rating',
//                 label: '$reviews Reviews',
//               ),
//               _buildInfoItem(
//                 icon: Icons.work_history,
//                 iconColor: AppColors.secondary,
//                 value: '${widget.doctorData['yearsOfExperience'] ?? 0}+',
//                 label: 'Experience',
//               ),
//               _buildInfoItem(
//                 icon: Icons.people,
//                 iconColor: AppColors.primary,
//                 value: '${(reviews * 2.5).floor()}+',
//                 label: 'Patients',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Info item with icon, value and label
//   Widget _buildInfoItem({
//     required IconData icon,
//     required Color iconColor,
//     required String value,
//     required String label,
//   }) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: iconColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: iconColor),
//         ),
//         SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: AppColors.gray,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Action buttons for message, video call and share
//   Widget _buildActionButtons() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Row(
//         children: [
//       Expanded(
//       child: _buildActionButton(
//       icon: Icons.message,
//         label: 'Message',
//         color: AppColors.primary,
//         onTap: () {
//           // Implement message functionality
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Message feature coming soon')),
//           );
//         },
//       ),
//     ),
//     SizedBox(width: 12),
//     Expanded(
//     child: _buildActionButton(
//     icon: Icons.videocam,
//     label: 'Video Call',
//     color: AppColors.secondary,
//     onTap: () {
//     // Implement video call functionality
//     ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text('Video call feature coming soon')),
//     );
//
//     },
//     ),
//     ),
//           SizedBox(width: 12),
//           _buildActionButton(
//             icon: Icons.share,
//             label: 'Share',
//             color: AppColors.gray,
//             isWide: false,
//             onTap: () {
//               // Implement share functionality
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Share feature coming soon')),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Action button widget
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     bool isWide = true,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12, horizontal: isWide ? 12 : 16),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Row(
//           mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 20),
//             if (isWide) SizedBox(width: 8),
//             if (isWide)
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: color,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Tab buttons for About, Experience, Reviews
//   Widget _buildTabButtons() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         children: [
//           _buildTabButton('About'),
//           _buildTabButton('Experience'),
//           _buildTabButton('Reviews'),
//         ],
//       ),
//     );
//   }
//
//   // Individual tab button
//   Widget _buildTabButton(String tabName) {
//     final bool isSelected = _selectedTab == tabName;
//
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             _selectedTab = tabName;
//           });
//         },
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(
//                 color: isSelected ? AppColors.primary : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//           ),
//           child: Center(
//             child: Text(
//               tabName,
//               style: TextStyle(
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 color: isSelected ? AppColors.primary : AppColors.gray,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Content for selected tab
//   Widget _buildTabContent() {
//     switch (_selectedTab) {
//       case 'About':
//         return _buildAboutContent();
//       case 'Experience':
//         return _buildExperienceContent();
//       case 'Reviews':
//         return _buildReviewsContent();
//       default:
//         return _buildAboutContent();
//     }
//   }
//
//   // About tab content
//   Widget _buildAboutContent() {
//     final String about = widget.doctorData['about'] ?? 'No information provided';
//     final List<String> languages = List<String>.from(widget.doctorData['languages'] ?? []);
//
//     return Padding(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'About Doctor',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 12),
//           Text(
//             about,
//             style: TextStyle(
//               color: AppColors.dark.withOpacity(0.7),
//               height: 1.5,
//             ),
//           ),
//           SizedBox(height: 24),
//           Text(
//             'Languages',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 12),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: languages.map((language) {
//               return Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: AppColors.light,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: AppColors.gray.withOpacity(0.3)),
//                 ),
//                 child: Text(
//                   language,
//                   style: TextStyle(
//                     color: AppColors.dark,
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//           SizedBox(height: 24),
//           Text(
//             'Working Hours',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 12),
//           _buildAvailabilityCalendar(),
//         ],
//       ),
//     );
//   }
//
//   // Calendar widget for doctor availability
//   Widget _buildAvailabilityCalendar() {
//     Map<String, dynamic> availability = widget.doctorData['availability'] ?? {};
//     List<String> weekdays = [
//       'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
//     ];
//
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: weekdays.map((day) {
//             final shortDay = day.substring(0, 3);
//             final bool isAvailable = availability.containsKey(day) &&
//                 availability[day] is List &&
//                 (availability[day] as List).isNotEmpty;
//             final bool isSelected = _selectedDay == day;
//
//             return GestureDetector(
//               onTap: isAvailable ? () {
//                 setState(() {
//                   _selectedDay = isSelected ? '' : day;
//                 });
//               } : null,
//               child: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? AppColors.primary
//                       : (isAvailable ? AppColors.light : Colors.transparent),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isAvailable
//                         ? (isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.3))
//                         : Colors.transparent,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     shortDay,
//                     style: TextStyle(
//                       color: isSelected
//                           ? AppColors.white
//                           : (isAvailable ? AppColors.dark : AppColors.gray),
//                       fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//         if (_selectedDay.isNotEmpty &&
//             availability.containsKey(_selectedDay) &&
//             availability[_selectedDay] is List)
//           Container(
//             margin: EdgeInsets.only(top: 16),
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.light,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '$_selectedDay Availability',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primary,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: (availability[_selectedDay] as List).map<Widget>((slot) {
//                     return Container(
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         _formatTimeSlot(slot.toString()),
//                         style: TextStyle(
//                           color: AppColors.dark,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//
//   // Format time slot from Firebase
//   String _formatTimeSlot(String timeCode) {
//     List<String> parts = timeCode.split(":");
//     if (parts.length >= 2) {
//       int hour = int.tryParse(parts[0]) ?? 0;
//       int period = hour >= 12 ? 1 : 0; // 0 for AM, 1 for PM
//       hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//       return '$hour:00 ${period == 0 ? 'AM' : 'PM'}';
//     }
//     return timeCode;
//   }
//
//   // Experience tab content
//   Widget _buildExperienceContent() {
//     final String qualifications = widget.doctorData['qualifications'] ?? 'Not specified';
//     final String institutions = widget.doctorData['affiliatedInstitutions'] ?? 'Not specified';
//     final String licenseNumber = widget.doctorData['licenseNumber'] ?? 'Not specified';
//     final int experience = widget.doctorData['yearsOfExperience'] ?? 0;
//
//     return Padding(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildExperienceItem(
//             title: 'Education & Qualifications',
//             icon: Icons.school,
//             content: qualifications,
//           ),
//           _buildExperienceItem(
//             title: 'Work Experience',
//             icon: Icons.work,
//             content: '$experience years of clinical experience',
//           ),
//           _buildExperienceItem(
//             title: 'Affiliated Hospitals',
//             icon: Icons.local_hospital,
//             content: institutions,
//           ),
//           _buildExperienceItem(
//             title: 'License Information',
//             icon: Icons.badge,
//             content: 'License #$licenseNumber',
//             isLast: true,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Experience item with icon and content
//   Widget _buildExperienceItem({
//     required String title,
//     required IconData icon,
//     required String content,
//     bool isLast = false,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               icon,
//               color: AppColors.primary,
//               size: 24,
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   content,
//                   style: TextStyle(
//                     color: AppColors.dark.withOpacity(0.7),
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Reviews tab content
//   Widget _buildReviewsContent() {
//     return Padding(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildReviewSummary(),
//           SizedBox(height: 24),
//           Text(
//             'Patient Reviews',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 16),
//           widget.doctorData['totalReviews'] == 0 || widget.doctorData['totalReviews'] == null
//               ? _buildNoReviewsMessage()
//               : _buildMockReviews(),
//         ],
//       ),
//     );
//   }
//
//   // Review summary with rating bars
//   Widget _buildReviewSummary() {
//     final double rating = (widget.doctorData['rating'] ?? 0).toDouble();
//     final int reviews = widget.doctorData['totalReviews'] ?? 0;
//
//     // Mock distribution for rating bars
//     final List<double> distribution = [0.7, 0.15, 0.1, 0.03, 0.02];
//
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.light,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           Column(
//             children: [
//               Text(
//                 rating.toStringAsFixed(1),
//                 style: TextStyle(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.dark,
//                 ),
//               ),
//               SizedBox(height: 4),
//               RatingBar.builder(
//                 initialRating: rating,
//                 minRating: 0,
//                 direction: Axis.horizontal,
//                 allowHalfRating: true,
//                 itemCount: 5,
//                 itemSize: 18,
//                 ignoreGestures: true,
//                 itemBuilder: (context, _) => Icon(
//                   Icons.star,
//                   color: AppColors.warning,
//                 ),
//                 onRatingUpdate: (_) {},
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Based on $reviews reviews',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.gray,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(width: 24),
//           Expanded(
//             child: Column(
//               children: List.generate(5, (index) {
//                 final int star = 5 - index;
//                 final double percentage = reviews > 0 ? distribution[index] : 0;
//
//                 return Padding(
//                   padding: EdgeInsets.only(bottom: index == 4 ? 0 : 4),
//                   child: Row(
//                     children: [
//                       Text(
//                         '$star',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(width: 4),
//                       Icon(
//                         Icons.star,
//                         size: 12,
//                         color: AppColors.warning,
//                       ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(4),
//                           child: LinearProgressIndicator(
//                             value: percentage,
//                             backgroundColor: AppColors.gray.withOpacity(0.2),
//                             color: AppColors.primary,
//                             minHeight: 8,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         '${(percentage * 100).toInt()}%',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: AppColors.gray,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Message when there are no reviews
//   Widget _buildNoReviewsMessage() {
//     return Center(
//       child: Column(
//         children: [
//           SizedBox(height: 24),
//           Icon(
//             Icons.rate_review_outlined,
//             size: 64,
//             color: AppColors.gray.withOpacity(0.5),
//           ),
//           SizedBox(height: 16),
//           Text(
//             'No Reviews Yet',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.dark,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Be the first to leave a review after your appointment',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: AppColors.gray,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Mock reviews for demonstration
//   Widget _buildMockReviews() {
//     // Creating mock reviews for demonstration
//     List<Map<String, dynamic>> mockReviews = [
//       {
//         'name': 'Sarah Johnson',
//         'date': '2 weeks ago',
//         'rating': 5.0,
//         'content': 'Excellent doctor! Very attentive and explained everything clearly. Would highly recommend.',
//       },
//       {
//         'name': 'Michael Brown',
//         'date': '1 month ago',
//         'rating': 4.5,
//         'content': 'Great experience. The doctor was knowledgeable and took time to address all my concerns.',
//       },
//     ];
//
//     return Column(
//       children: mockReviews.map((review) {
//         return Container(
//           margin: EdgeInsets.only(bottom: 16),
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: AppColors.light,
//                     child: Text(
//                       review['name'].toString().substring(0, 1),
//                       style: TextStyle(
//                         color: AppColors.primary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           review['name'],
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           review['date'],
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.gray,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   RatingBar.builder(
//                     initialRating: review['rating'],
//                     minRating: 0,
//                     direction: Axis.horizontal,
//                     allowHalfRating: true,
//                     itemCount: 5,
//                     itemSize: 14,
//                     ignoreGestures: true,
//                     itemBuilder: (context, _) => Icon(
//                       Icons.star,
//                       color: AppColors.warning,
//                     ),
//                     onRatingUpdate: (_) {},
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Text(
//                 review['content'],
//                 style: TextStyle(
//                   color: AppColors.dark.withOpacity(0.8),
//                   height: 1.5,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   // Placeholder for profile image
//   Widget _buildProfilePlaceholder() {
//     return Container(
//       color: AppColors.light,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.person,
//               size: 64,
//               color: AppColors.gray,
//             ),
//             SizedBox(height: 8),
//             Text(
//               'No Profile Photo',
//               style: TextStyle(
//                 color: AppColors.gray,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Book appointment button
//   Widget _buildBookAppointmentButton() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: ElevatedButton(
//           onPressed: () {
//             // Implement appointment booking functionality
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Booking feature coming soon')),
//             );
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             foregroundColor: AppColors.white,
//             padding: EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: Text(
//             'Book Appointment',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CategoryItem {
//   final String name;
//   final IconData icon;
//   final Color color;
//
//   CategoryItem(this.name, this.icon, this.color);
// }