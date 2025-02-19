// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:p1/theme.dart';
//
// class AIBotScreen extends StatefulWidget {
//   @override
//   _AIBotScreenState createState() => _AIBotScreenState();
// }
//
// class _AIBotScreenState extends State<AIBotScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final User? _currentUser = FirebaseAuth.instance.currentUser;
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }
//
//   Future<void> _fetchUserData() async {
//     try {
//       if (_currentUser != null) {
//         print('Current User ID: ${_currentUser?.uid}'); // Debug print
//
//         // Fetch user details from 'users' collection
//         final userDoc = await _firestore.collection('users').doc(_currentUser?.uid).get();
//         if (userDoc.exists) {
//           setState(() {
//             userData = userDoc.data();
//             print('User Data: $userData'); // Debug print
//           });
//
//           // Fetch additional details based on role
//           if (userData?['role'] == 'Doctor') {
//             print('Fetching doctor data...'); // Debug print
//             final doctorDoc = await _firestore.collection('doctors').doc(_currentUser?.uid).get();
//             if (doctorDoc.exists) {
//               setState(() {
//                 userData?.addAll(doctorDoc.data()!);
//                 print('Doctor Data: ${doctorDoc.data()}'); // Debug print
//               });
//             } else {
//               print('Doctor document does not exist'); // Debug print
//             }
//           } else if (userData?['role'] == 'Patient') {
//             print('Fetching patient data...'); // Debug print
//             final patientDoc = await _firestore.collection('patients').doc(_currentUser?.uid).get();
//             if (patientDoc.exists) {
//               setState(() {
//                 userData?.addAll(patientDoc.data()!);
//                 print('Patient Data: ${patientDoc.data()}'); // Debug print
//               });
//             } else {
//               print('Patient document does not exist'); // Debug print
//             }
//           } else {
//             print('Role not recognized: ${userData?['role']}'); // Debug print
//           }
//
//           setState(() {
//             isLoading = false;
//           });
//         } else {
//           print('User document does not exist'); // Debug print
//           setState(() {
//             isLoading = false;
//           });
//         }
//       } else {
//         print('No current user'); // Debug print
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching user data: $e'); // Debug print
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('CureAI Bot'),
//           backgroundColor: AppColors.primary,
//         ),
//         body: Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('CureAI Bot'),
//         backgroundColor: AppColors.primary,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: userData == null
//             ? Center(child: Text('Failed to load user data'))
//             : ListView(
//           children: [
//             Text(
//               'Welcome, ${userData?['nickname'] ?? 'User'}!',
//               style: Theme.of(context).textTheme.titleLarge,
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             if (userData?['role'] == 'Doctor') ...[
//               Text(
//                 'Doctor Details:',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               SizedBox(height: 10),
//               ListTile(
//                 title: Text('Specialty'),
//                 subtitle: Text(userData?['specialty'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Qualifications'),
//                 subtitle: Text(userData?['qualifications'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Years of Experience'),
//                 subtitle: Text('${userData?['yearsOfExperience'] ?? 'N/A'}'),
//               ),
//               ListTile(
//                 title: Text('License Number'),
//                 subtitle: Text(userData?['licenseNumber'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Affiliated Institutions'),
//                 subtitle: Text(userData?['affiliatedInstitutions'] ?? 'N/A'),
//               ),
//             ] else if (userData?['role'] == 'Patient') ...[
//               Text(
//                 'Patient Details:',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               SizedBox(height: 10),
//               ListTile(
//                 title: Text('Age'),
//                 subtitle: Text('${userData?['age'] ?? 'N/A'}'),
//               ),
//               ListTile(
//                 title: Text('Chronic Conditions'),
//                 subtitle: Text(
//                   userData?['hasChronicConditions'] == true
//                       ? (userData?['chronicConditions'] ?? 'Yes')
//                       : 'No',
//                 ),
//               ),
//               ListTile(
//                 title: Text('Family Health History'),
//                 subtitle: Text(
//                   userData?['hasFamilyHealthHistory'] == true
//                       ? (userData?['familyHealthHistory'] ?? 'Yes')
//                       : 'No',
//                 ),
//               ),
//               ListTile(
//                 title: Text('Known Allergies'),
//                 subtitle: Text(userData?['knownAllergies'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Current Medications'),
//                 subtitle: Text(userData?['currentMedications'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Medication History'),
//                 subtitle: Text(userData?['medicationHistory'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Smoking Intensity'),
//                 subtitle: Text(userData?['smokingIntensity'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Physical Activity Level'),
//                 subtitle: Text(userData?['physicalActivityLevel'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Sleep Pattern'),
//                 subtitle: Text(userData?['sleepPattern'] ?? 'N/A'),
//               ),
//               ListTile(
//                 title: Text('Stress Level'),
//                 subtitle: Text(userData?['stressLevel'] ?? 'N/A'),
//               ),
//             ] else ...[
//               Text(
//                 'Unknown role or no additional details available.',
//                 style: Theme.of(context).textTheme.bodyLarge,
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'login_screen.dart';
// import 'chat_screen.dart';
// import 'profile_screen.dart';
// import 'doctor_list_screen.dart';
// import 'package:p1/theme.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late String nickname;
//   late String role;
//   int _currentIndex = 0;
//   //final CarouselController _carouselController = CarouselController();
//   final CarouselSliderController? _carouselController = CarouselSliderController();
//
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserDetails();
//   }
//
//   Future<void> _fetchUserDetails() async {
//     try {
//       User? user = _auth.currentUser;
//       if (user != null) {
//         DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
//         if (userDoc.exists) {
//           setState(() {
//             nickname = userDoc['nickname'];
//             role = userDoc['role'];
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching user details: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(nickname != null ? 'Welcome, $nickname!' : 'Welcome!'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () async {
//               await _auth.signOut();
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => LoginScreen()),
//               );
//             },
//           ),
//         ],
//         backgroundColor: AppColors.primary,
//       ),
//       body: nickname == null || role == null
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Column(
//           children: [
//             // Sliding Image Carousel
//             CarouselSlider(
//               items: [
//                 'assets/image1.jpg',
//                 'assets/image2.jpg',
//                 'assets/image3.jpg',
//               ].map((item) => Image.asset(item, fit: BoxFit.cover, width: double.infinity)).toList(),
//               carouselController: _carouselController,
//               options: CarouselOptions(
//                 autoPlay: true,
//                 aspectRatio: 2.0,
//                 enlargeCenterPage: true,
//                 onPageChanged: (index, reason) {
//                   setState(() {
//                     _currentIndex = index;
//                   });
//                 },
//               ),
//             ),
//
//
//             // Dots Indicator
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 'assets/image1.jpg',
//                 'assets/image2.jpg',
//                 'assets/image3.jpg',
//               ].asMap().entries.map((entry) {
//                 return GestureDetector(
//                   onTap: () {
//                     if (_carouselController != null) {
//                       _carouselController!.jumpToPage(entry.key);
//                     }
//                   },
//                   child: Container(
//                     width: 12.0,
//                     height: 12.0,
//                     margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: (Theme.of(context).brightness == Brightness.dark
//                           ? Colors.white
//                           : Colors.black)
//                           .withOpacity(_currentIndex == entry.key ? 0.9 : 0.4),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//
//             // Upcoming Appointments Container
//             Container(
//               margin: EdgeInsets.all(16.0),
//               padding: EdgeInsets.all(16.0),
//               decoration: BoxDecoration(
//                 color: AppColors.secondary.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 8.0,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Upcoming Appointments',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   SizedBox(height: 10),
//                   // Fetch and display upcoming appointment details here
//                   FutureBuilder<QuerySnapshot>(
//                     future: _firestore.collection('appointments').where('userId', isEqualTo: _auth.currentUser?.uid).where('date', isGreaterThanOrEqualTo: Timestamp.now()).get(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return CircularProgressIndicator();
//                       }
//                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                         return Text('No upcoming appointments.');
//                       }
//                       var appointment = snapshot.data!.docs.first;
//                       var date = (appointment['date'] as Timestamp).toDate();
//                       var remainingTime = date.difference(DateTime.now());
//                       return Text('Next appointment in ${remainingTime.inDays} days and ${remainingTime.inHours % 24} hours.');
//                     },
//                   ),
//                 ],
//               ),
//             ),
//
//             // Previous Appointments Section
//             Container(
//               margin: EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Previous Appointments',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   SizedBox(height: 10),
//                   // Fetch and display previous appointments here
//                   StreamBuilder<QuerySnapshot>(
//                     stream: _firestore.collection('appointments').where('userId', isEqualTo: _auth.currentUser?.uid).where('date', isLessThan: Timestamp.now()).snapshots(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return CircularProgressIndicator();
//                       }
//                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                         return Text('No previous appointments.');
//                       }
//                       return Column(
//                         children: snapshot.data!.docs.map((doc) {
//                           var date = (doc['date'] as Timestamp).toDate();
//                           return ListTile(
//                             title: Text('Appointment on ${date.toLocal()}'),
//                             subtitle: Text('With Dr. ${doc['doctorName']}'),
//                           );
//                         }).toList(),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//             switch (index) {
//               case 0:
//               // Home
//                 break;
//               case 1:
//               // Chat
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ChatScreen()),
//                 );
//                 break;
//               case 2:
//               // Doctor
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => DoctorListScreen()),
//                 );
//                 break;
//               case 3:
//               // Profile
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfileScreen()),
//                 );
//                 break;
//             }
//           });
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'Chat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.local_hospital),
//             label: 'Doctor',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: AppColors.gray,
//       ),
//     );
//   }
// }

// ignore_for_file: file_names, library_private_types_in_public_api, empty_catches, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // New package
import 'login_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'doctor_list_screen.dart';
import 'package:p1/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? nickname;
  String? role;
  int _currentIndex = 0;

  // Carousel Controller
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            nickname = userDoc['nickname'];
            role = userDoc['role'];
          });
        }
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nickname != null ? 'Welcome, $nickname!' : 'Welcome!'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
        backgroundColor: AppColors.primary,
      ),
      body: nickname == null || role == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Sliding Image Carousel
            SizedBox(
              height: 200,
              child: PageView(
                controller: _pageController,
                children: [
                  'assets/image1.jpg',
                  'assets/image2.jpg',
                  'assets/image3.jpg',
                ].map((item) => Image.asset(item, fit: BoxFit.cover)).toList(),
              ),
            ),

            // Dots Indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.gray,
              ),
            ),

            // Upcoming Appointments Container
            Container(
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  // Fetch and display upcoming appointment details here
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('appointments')
                        .where('userId', isEqualTo: _auth.currentUser?.uid)
                        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No upcoming appointments.');
                      }
                      var appointment = snapshot.data!.docs.first;
                      var date = (appointment['date'] as Timestamp).toDate();
                      var remainingTime = date.difference(DateTime.now());
                      return Text('Next appointment in ${remainingTime.inDays} days and ${remainingTime.inHours % 24} hours.');
                    },
                  ),
                ],
              ),
            ),

            // Previous Appointments Section
            Container(
              margin: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous Appointments',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  // Fetch and display previous appointments here
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('appointments')
                        .where('userId', isEqualTo: _auth.currentUser?.uid)
                        .where('date', isLessThan: Timestamp.now())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No previous appointments.');
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          var date = (doc['date'] as Timestamp).toDate();
                          return ListTile(
                            title: Text('Appointment on ${date.toLocal()}'),
                            subtitle: Text('With Dr. ${doc['doctorName']}'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
                break;
              case 2:
                Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorListingScreen()));
                break;
              case 3:
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                break;
            }
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray,
      ),
    );
  }
}

