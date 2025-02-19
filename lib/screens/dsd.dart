// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:p1/theme.dart';
// //
// // class DoctorListScreen extends StatefulWidget {
// //   const DoctorListScreen({super.key});
// //
// //   @override
// //   _DoctorListScreenState createState() => _DoctorListScreenState();
// // }
// //
// // class _DoctorListScreenState extends State<DoctorListScreen> {
// //   final TextEditingController _searchController = TextEditingController();
// //   String _searchQuery = '';
// //   BodyPart _selectedBodyPart = BodyPart.generalHealth;
// //
// //   // List of body parts with icons and related specializations
// //   late List<Map<String, dynamic>> _bodyParts;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _bodyParts = BodyPart.values.map((bodyPart) {
// //       return {
// //         'bodyPart': bodyPart,
// //         'icon': _getBodyPartIcon(bodyPart),
// //         'displayName': bodyPart.displayName,
// //         'specializations': bodyPart.relatedSpecializations,
// //       };
// //     }).toList();
// //   }
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Find a Doctor',
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //               color: AppColors.white,
// //               fontWeight: FontWeight.bold,
// //             )),
// //         backgroundColor: AppColors.primary,
// //         elevation: 0,
// //         centerTitle: true,
// //       ),
// //       body: Column(
// //         children: [
// //           // Search Bar
// //           Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: TextField(
// //               controller: _searchController,
// //               decoration: InputDecoration(
// //                 hintText: 'Search by name or specialty...',
// //                 prefixIcon: Icon(Icons.search, color: AppColors.secondary),
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(10),
// //                   borderSide: BorderSide(color: AppColors.gray),
// //                 ),
// //                 focusedBorder: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(10),
// //                   borderSide: BorderSide(color: AppColors.primary, width: 2),
// //                 ),
// //                 filled: true,
// //                 fillColor: AppColors.white,
// //               ),
// //               onChanged: (value) {
// //                 setState(() {
// //                   _searchQuery = value;
// //                 });
// //               },
// //             ),
// //           ),
// //
// //           // Body Parts Filter
// //           SizedBox(
// //             height: 100, // Increased height for better visibility
// //             child: ListView.builder(
// //               scrollDirection: Axis.horizontal,
// //               itemCount: _bodyParts.length,
// //               itemBuilder: (context, index) {
// //                 final bodyPart = _bodyParts[index];
// //                 return Padding(
// //                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
// //                   child: FilterChip(
// //                     label: Row(
// //                       children: [
// //                         Icon(bodyPart['icon'], size: 16, color: _selectedBodyPart == bodyPart['bodyPart'] ? AppColors.primary : AppColors.dark),
// //                         const SizedBox(width: 4),
// //                         Text(bodyPart['displayName']),
// //                       ],
// //                     ),
// //                     selected: _selectedBodyPart == bodyPart['bodyPart'],
// //                     onSelected: (selected) {
// //                       setState(() {
// //                         _selectedBodyPart = bodyPart['bodyPart'];
// //                       });
// //                     },
// //                     selectedColor: AppColors.secondary.withOpacity(0.2),
// //                     checkmarkColor: AppColors.primary,
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           // Doctors Grid
// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('doctors')
// //                   .where('status', isEqualTo: 'active') // Ensure only active doctors are shown
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return Center(child: CircularProgressIndicator(color: AppColors.primary));
// //                 }
// //                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                   return Center(child: Text('No doctors found.', style: Theme.of(context).textTheme.bodyMedium));
// //                 }
// //
// //                 // Fetch doctors and join with users collection
// //                 final doctors = snapshot.data!.docs;
// //                 return FutureBuilder<List<Map<String, dynamic>>>(
// //                   future: _fetchDoctorDetails(doctors),
// //                   builder: (context, doctorDetailsSnapshot) {
// //                     if (doctorDetailsSnapshot.connectionState == ConnectionState.waiting) {
// //                       return Center(child: CircularProgressIndicator(color: AppColors.primary));
// //                     }
// //                     if (!doctorDetailsSnapshot.hasData || doctorDetailsSnapshot.data!.isEmpty) {
// //                       return Center(child: Text('No matching doctors found.', style: Theme.of(context).textTheme.bodyMedium));
// //                     }
// //
// //                     // Filter doctors based on search query and selected body part
// //                     final filteredDoctors = doctorDetailsSnapshot.data!.where((doctor) {
// //                       final name = doctor['nickname'].toString().toLowerCase();
// //                       final specialty = doctor['specialization'].toString().toLowerCase();
// //                       final query = _searchQuery.toLowerCase();
// //
// //                       // Match search query
// //                       final matchesQuery = name.contains(query) || specialty.contains(query);
// //
// //                       // Match body part specializations
// //                       final specializations = _selectedBodyPart.relatedSpecializations;
// //                       final matchesBodyPart = specializations.any((spec) => specialty.contains(spec.toLowerCase()));
// //
// //                       return matchesQuery && matchesBodyPart;
// //                     }).toList();
// //
// //                     if (filteredDoctors.isEmpty) {
// //                       return Center(child: Text('No matching doctors found.', style: Theme.of(context).textTheme.bodyMedium));
// //                     }
// //
// //                     return GridView.builder(
// //                       padding: const EdgeInsets.all(16.0),
// //                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //                         crossAxisCount: 2,
// //                         crossAxisSpacing: 16.0,
// //                         mainAxisSpacing: 16.0,
// //                         childAspectRatio: 0.8,
// //                       ),
// //                       itemCount: filteredDoctors.length,
// //                       itemBuilder: (context, index) {
// //                         final doctor = filteredDoctors[index];
// //                         return _buildDoctorCard(doctor);
// //                       },
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // Fetch doctor details by joining with users collection
// //   Future<List<Map<String, dynamic>>> _fetchDoctorDetails(List<QueryDocumentSnapshot> doctors) async {
// //     final List<Map<String, dynamic>> doctorDetails = [];
// //     for (final doctor in doctors) {
// //       final userDoc = await FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(doctor['uid'])
// //           .get();
// //       if (userDoc.exists) {
// //         doctorDetails.add({
// //           ...doctor.data() as Map<String, dynamic>,
// //           'nickname': userDoc['nickname'],
// //         });
// //       }
// //     }
// //     return doctorDetails;
// //   }
// //
// //   Widget _buildDoctorCard(Map<String, dynamic> doctor) {
// //     return Card(
// //       elevation: 4,
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: InkWell(
// //         borderRadius: BorderRadius.circular(12),
// //         onTap: () {
// //           // Navigate to Doctor Details Screen
// //         },
// //         child: Padding(
// //           padding: const EdgeInsets.all(16.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               // Doctor Image
// //               Center(
// //                 child: CircleAvatar(
// //                   radius: 40,
// //                   backgroundImage: doctor['profileImageUrl'] != null
// //                       ? NetworkImage(doctor['profileImageUrl'])
// //                       : AssetImage('assets/default_doctor.png') as ImageProvider,
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //
// //               // Doctor Name
// //               Text(
// //                 doctor['nickname'],
// //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //                 maxLines: 1,
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //               const SizedBox(height: 8),
// //
// //               // Doctor Specialization
// //               Text(
// //                 doctor['specialization'],
// //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                   color: AppColors.dark.withOpacity(0.7),
// //                 ),
// //                 maxLines: 1,
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //               const SizedBox(height: 8),
// //
// //               // Doctor Experience
// //               Text(
// //                 '${doctor['experience']} years of experience',
// //                 style: Theme.of(context).textTheme.bodySmall,
// //               ),
// //               const SizedBox(height: 8),
// //
// //               // Doctor Rating
// //               Row(
// //                 children: [
// //                   Icon(Icons.star, color: AppColors.warning, size: 16),
// //                   const SizedBox(width: 4),
// //                   Text(
// //                     '${doctor['rating'] ?? '0.0'} (${doctor['totalReviews'] ?? '0'} reviews)',
// //                     style: Theme.of(context).textTheme.bodySmall,
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 8),
// //
// //               // Doctor Fee
// //               Text(
// //                 '₹${doctor['consultationFee']} per consultation',
// //                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
// //                   color: AppColors.primary,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Helper method to get icons for body parts
// //   IconData _getBodyPartIcon(BodyPart bodyPart) {
// //     switch (bodyPart) {
// //       case BodyPart.eyes:
// //         return Icons.remove_red_eye;
// //       case BodyPart.heart:
// //         return Icons.favorite;
// //       case BodyPart.skin:
// //         return Icons.face;
// //       case BodyPart.ears:
// //         return Icons.hearing;
// //       case BodyPart.hair:
// //         return Icons.cut;
// //       case BodyPart.bones:
// //         return Icons.accessibility;
// //       case BodyPart.brain:
// //         return Icons.psychology;
// //       case BodyPart.throat:
// //         return Icons.mic;
// //       case BodyPart.teeth:
// //         return Icons.medical_services;
// //       case BodyPart.lungs:
// //         return Icons.air;
// //       case BodyPart.stomach:
// //         return Icons.fastfood;
// //       case BodyPart.kidneys:
// //         return Icons.water_drop;
// //       case BodyPart.reproductiveSystem:
// //         return Icons.female;
// //       case BodyPart.muscles:
// //         return Icons.fitness_center;
// //       case BodyPart.generalHealth:
// //         return Icons.medical_services;
// //     }
// //   }
// // }
// //
// // // BodyPart Enum and Extension
// // enum BodyPart {
// //   eyes,
// //   heart,
// //   skin,
// //   ears,
// //   hair,
// //   bones,
// //   brain,
// //   throat,
// //   teeth,
// //   lungs,
// //   stomach,
// //   kidneys,
// //   reproductiveSystem,
// //   muscles,
// //   generalHealth
// // }
// //
// // extension BodyPartExtension on BodyPart {
// //   String get displayName {
// //     switch (this) {
// //       case BodyPart.eyes:
// //         return 'Eyes';
// //       case BodyPart.heart:
// //         return 'Heart';
// //       case BodyPart.skin:
// //         return 'Skin';
// //       case BodyPart.ears:
// //         return 'Ears';
// //       case BodyPart.hair:
// //         return 'Hair';
// //       case BodyPart.bones:
// //         return 'Bones';
// //       case BodyPart.brain:
// //         return 'Brain';
// //       case BodyPart.throat:
// //         return 'Throat';
// //       case BodyPart.teeth:
// //         return 'Teeth';
// //       case BodyPart.lungs:
// //         return 'Lungs';
// //       case BodyPart.stomach:
// //         return 'Stomach';
// //       case BodyPart.kidneys:
// //         return 'Kidneys';
// //       case BodyPart.reproductiveSystem:
// //         return 'Reproductive System';
// //       case BodyPart.muscles:
// //         return 'Muscles';
// //       case BodyPart.generalHealth:
// //         return 'General Health';
// //     }
// //   }
// //
// //   List<String> get relatedSpecializations {
// //     switch (this) {
// //       case BodyPart.eyes:
// //         return ['Ophthalmologist'];
// //       case BodyPart.heart:
// //         return ['Cardiologist'];
// //       case BodyPart.skin:
// //         return ['Dermatologist'];
// //       case BodyPart.ears:
// //         return ['ENT Specialist'];
// //       case BodyPart.hair:
// //         return ['Dermatologist'];
// //       case BodyPart.bones:
// //         return ['Orthopedic Surgeon'];
// //       case BodyPart.brain:
// //         return ['Neurologist', 'Psychiatrist'];
// //       case BodyPart.throat:
// //         return ['ENT Specialist'];
// //       case BodyPart.teeth:
// //         return ['Dentist'];
// //       case BodyPart.lungs:
// //         return ['Pulmonologist'];
// //       case BodyPart.stomach:
// //         return ['Gastroenterologist'];
// //       case BodyPart.kidneys:
// //         return ['Urologist'];
// //       case BodyPart.reproductiveSystem:
// //         return ['Gynecologist', 'Urologist'];
// //       case BodyPart.muscles:
// //         return ['Physiotherapist', 'Orthopedic Surgeon'];
// //       case BodyPart.generalHealth:
// //         return ['General Physician', 'Family Medicine'];
// //     }
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:p1/theme.dart';
//
// import 'doctor_detail.page.dart';
//
// // Main Screen: Doctor Browse Page
// class DoctorBrowsePage extends StatefulWidget {
//   const DoctorBrowsePage({Key? key}) : super(key: key);
//
//   @override
//   State<DoctorBrowsePage> createState() => _DoctorBrowsePageState();
// }
//
// class _DoctorBrowsePageState extends State<DoctorBrowsePage> {
//   final searchController = TextEditingController();
//   String? selectedCategory;
//   bool isLoading = false;
//
//   // Expanded specialization categories
//   final List<Map<String, dynamic>> categories = [
//     {'name': 'Heart', 'icon': Icons.favorite, 'specialization': 'Cardiology'},
//     {'name': 'Skin', 'icon': Icons.face, 'specialization': 'Dermatology'},
//     {'name': 'Hormones', 'icon': Icons.biotech, 'specialization': 'Endocrinology'},
//     {'name': 'Family', 'icon': Icons.family_restroom, 'specialization': 'Family Medicine'},
//     {'name': 'Digestive', 'icon': Icons.restaurant, 'specialization': 'Gastroenterology'},
//     {'name': 'Brain', 'icon': Icons.psychology, 'specialization': 'Neurology'},
//     {'name': 'Pregnancy', 'icon': Icons.pregnant_woman, 'specialization': 'Obstetrics'},
//     {'name': 'Children', 'icon': Icons.child_care, 'specialization': 'Pediatrics'},
//     {'name': 'Mental', 'icon': Icons.mood, 'specialization': 'Psychiatry'},
//     {'name': 'Bones', 'icon': Icons.accessibility_new, 'specialization': 'Orthopedics'},
//     {'name': 'Eyes', 'icon': Icons.visibility, 'specialization': 'Ophthalmology'},
//     {'name': 'Dental', 'icon': Icons.personal_injury, 'specialization': 'Dentistry'},
//   ];
//
//   // Sample doctor data for demonstration
//   final List<Map<String, dynamic>> sampleDoctors = [
//     //Dummy data
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Find Doctors'),
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Stats Card
//           _buildStatsCard(),
//
//           // Search Box
//           _buildSearchBox(),
//
//           // Categories Horizontal List
//           _buildCategoriesList(),
//
//           // Divider
//           Divider(
//             color: AppColors.gray.withOpacity(0.5),
//             thickness: 1,
//             height: 24,
//           ),
//
//           // Doctor Grid
//           Expanded(
//             child: _buildDoctorGrid(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatsCard() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: FutureBuilder<int>(
//         // For demo purposes, use sample data count instead of Firestore
//         future: Future.value(sampleDoctors.length),
//         builder: (context, snapshot) {
//           int doctorCount = snapshot.data ?? sampleDoctors.length;
//
//           return Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppColors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.medical_services_outlined,
//                   color: AppColors.white,
//                   size: 36,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Available Doctors',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: AppColors.white.withOpacity(0.9),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '$doctorCount Doctors',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: AppColors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildSearchBox() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: TextField(
//         controller: searchController,
//         decoration: InputDecoration(
//           hintText: 'Search by name or specialization',
//           prefixIcon: const Icon(Icons.search, color: AppColors.gray),
//           suffixIcon: searchController.text.isNotEmpty
//               ? IconButton(
//             icon: const Icon(Icons.clear, color: AppColors.gray),
//             onPressed: () {
//               searchController.clear();
//               setState(() {});
//             },
//           )
//               : null,
//         ),
//         onChanged: (value) {
//           setState(() {});
//         },
//       ),
//     );
//   }
//
//   Widget _buildCategoriesList() {
//     return Container(
//       height: 110,
//       margin: const EdgeInsets.only(top: 16),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         itemCount: categories.length,
//         itemBuilder: (context, index) {
//           final category = categories[index];
//           final isSelected = selectedCategory == category['specialization'];
//
//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 if (isSelected) {
//                   selectedCategory = null;
//                 } else {
//                   selectedCategory = category['specialization'];
//                 }
//               });
//             },
//             child: Container(
//               width: 80,
//               margin: const EdgeInsets.symmetric(horizontal: 8),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: isSelected ? AppColors.primary : AppColors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.gray.withOpacity(0.2),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       category['icon'],
//                       color: isSelected ? AppColors.white : AppColors.primary,
//                       size: 30,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     category['name'],
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                       color: isSelected ? AppColors.primary : AppColors.dark,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDoctorGrid() {
//     // Filter doctors based on search and category
//     var doctors = List<Map<String, dynamic>>.from(sampleDoctors);
//
//     // Apply search filter
//     if (searchController.text.isNotEmpty) {
//       final searchQuery = searchController.text.toLowerCase();
//       doctors = doctors.where((doctor) {
//         final nickname = (doctor['nickname'] ?? '').toString().toLowerCase();
//         final specialization = (doctor['specialization'] ?? '').toString().toLowerCase();
//         return nickname.contains(searchQuery) || specialization.contains(searchQuery);
//       }).toList();
//     }
//
//     // Apply category filter
//     if (selectedCategory != null) {
//       doctors = doctors.where((doctor) {
//         return doctor['specialization'] == selectedCategory;
//       }).toList();
//     }
//
//     if (doctors.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.search_off, size: 64, color: AppColors.gray),
//             const SizedBox(height: 16),
//             Text(
//               'No doctors found',
//               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 color: AppColors.gray,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Try adjusting your search criteria',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: AppColors.gray,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.75,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemCount: doctors.length,
//       itemBuilder: (context, index) {
//         final doctor = doctors[index];
//         return _buildDoctorCard(doctor);
//       },
//     );
//   }
//
//   Widget _buildDoctorCard(Map<String, dynamic> doctor) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DoctorDetailPage(doctorId: doctor['id'], doctorData: doctor),
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
//               blurRadius: 6,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Doctor Image & Specialization Badge
//             Stack(
//               children: [
//                 Container(
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.1),
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                   ),
//                   child: Center(
//                     child: Icon(
//                       Icons.account_circle,
//                       size: 80,
//                       color: AppColors.primary.withOpacity(0.7),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary,
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(8),
//                         bottomRight: Radius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       doctor['specialization'] ?? 'Specialist',
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: AppColors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // Doctor Info
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     doctor['nickname'] ?? 'Doctor',
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${doctor['qualification'] ?? 'MD'}',
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: AppColors.gray,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Icon(Icons.star, color: AppColors.warning, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${doctor['rating']?.toStringAsFixed(1) ?? '0.0'}',
//                         style: Theme.of(context).textTheme.bodySmall,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '(${doctor['totalReviews'] ?? '0'})',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppColors.gray,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Icon(Icons.attach_money, color: AppColors.success, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         '\$${doctor['consultationFee'] ?? '0'}',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           fontWeight: FontWeight.bold,
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
// }





// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p1/theme.dart';

// Main home screen with doctor search and listing
class DoctorExploreScreen extends StatefulWidget {
  const DoctorExploreScreen({super.key});

  @override
  State<DoctorExploreScreen> createState() => _DoctorExploreScreenState();
}

class _DoctorExploreScreenState extends State<DoctorExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "";
  List<String> specialties = [
    "Cardiology",
    "Ophthalmology",
    "Orthopedics",
    "Neurology",
    "Dermatology",
    "Pediatrics",
    "Gynecology",
    "Psychiatry",
  ];

  // Mapping between user-friendly categories and specializations
  Map<String, String> categoryToSpecialty = {
    "Heart": "Cardiology",
    "Eyes": "Ophthalmology",
    "Bones": "Orthopedics",
    "Brain": "Neurology",
    "Skin": "Dermatology",
    "Children": "Pediatrics",
    "Women's Health": "Gynecology",
    "Mental Health": "Psychiatry",
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Stats Header
          _buildHeaderSection(),

          // Categories
          _buildCategoriesSection(),

          // Doctor Listing
          Expanded(
            child: _buildDoctorGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor count stats
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                int doctorCount = 0;
                if (snapshot.hasData) {
                  doctorCount = snapshot.data!.size;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '$doctorCount Doctors Available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
          ),

          // Search Box
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Search by specialty...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categoryToSpecialty.length,
            itemBuilder: (context, index) {
              String category = categoryToSpecialty.keys.elementAt(index);
              return _buildCategoryItem(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category) {
    bool isSelected = _selectedCategory == category;

    // Icons mapping for categories
    Map<String, IconData> categoryIcons = {
      'Heart': Icons.favorite,
      'Eyes': Icons.visibility,
      'Bones': Icons.accessibility_new,
      'Brain': Icons.psychology,
      'Skin': Icons.face,
      'Children': Icons.child_care,
      'Women\'s Health': Icons.pregnant_woman,
      'Mental Health': Icons.sentiment_satisfied_alt,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? "" : category;
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcons[category] ?? Icons.medical_services,
              color: isSelected ? AppColors.white : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.white : AppColors.dark,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildDoctorQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.gray),
                const SizedBox(height: 16),
                Text(
                  'No doctors found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildDoctorCard(doc.id, data);
            },
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildDoctorQuery() {
    Query query = FirebaseFirestore.instance
        .collection('doctors')
        .where('status', isEqualTo: 'active');

    // Apply category filter if selected
    if (_selectedCategory.isNotEmpty) {
      String specialty = categoryToSpecialty[_selectedCategory] ?? '';
      if (specialty.isNotEmpty) {
        query = query.where('specialization', isEqualTo: specialty);
      }
    }

    // Apply search filter if text entered
    String searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      // Client-side filtering approach
      return query.snapshots().map((snapshot) {
        // Create a new list with filtered documents
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if specialization contains search text
          if (data.containsKey('specialization') && data['specialization'] != null) {
            final specialization = data['specialization'].toString().toLowerCase();
            if (specialization.contains(searchText)) {
              return true;
            }
          }

          // You could add additional fields to search here
          return false;
        }).toList();

        // Return a new QuerySnapshot with the filtered docs
        // This uses an internal constructor that maintains the QuerySnapshot interface
        return _CustomQuerySnapshot(
          docs: filteredDocs,
          metadata: snapshot.metadata,
          size: filteredDocs.length,
          docChanges: [],
        );
      });
    }

    return query.snapshots();
  }

  Widget _buildDoctorCard(String doctorId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => DoctorDetailScreen(doctorId: doctorId),
        //   ),
        // );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor image header with rating badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: AppColors.primary.withOpacity(0.15),
                    child: const Icon(
                      Icons.person,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['rating'] ?? 0.0}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Doctor info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fetch and display nickname from users collection
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['uid'])
                        .get(),
                    builder: (context, userSnapshot) {
                      String name = 'Loading...';
                      if (userSnapshot.hasData && userSnapshot.data != null) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        name = userData?['nickname'] ?? 'Unknown Doctor';
                      }

                      return Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),

                  const SizedBox(height: 4),

                  Text(
                    data['specialization'] ?? 'Specialist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 14,
                        color: AppColors.gray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data['experience'] ?? 0} yrs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.currency_rupee,
                        size: 14,
                        color: AppColors.gray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${data['consultationFee'] ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray,
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
}

// Helper class to create custom QuerySnapshot for client-side filtering
class _CustomQuerySnapshot extends QuerySnapshot {
  @override
  final List<QueryDocumentSnapshot> docs;
  @override
  final SnapshotMetadata metadata;
  @override
  final int size;
  @override
  final List<DocumentChange> docChanges;

  _CustomQuerySnapshot({
    required this.docs,
    required this.metadata,
    required this.size,
    required this.docChanges,
  });
}