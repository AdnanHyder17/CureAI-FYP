// lib/screens/doctor_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:p1/screens/login_screen.dart'; // For logout navigation
import 'package:p1/theme.dart';
// import 'package:p1/screens/chat_list_screen.dart'; // Replaced by AI Chat FAB
import 'package:p1/screens/profile_screen.dart';
import 'package:p1/screens/doctor_appointments_screen.dart';
import 'package:p1/screens/doctor_patients_list_screen.dart';
import 'package:p1/screens/ai_chatbot_screen.dart'; // Import AI Chatbot Screen

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0; // 0: Home, 1: Bookings, 2: Patients, 3: Profile
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // String? _doctorNickname; // Can be fetched in DoctorHomeTab directly

  // Screens for IndexedStack. ChatListScreen is removed from main tabs.
  final List<Widget> _screens = [
    const DoctorHomeTab(),                // Index 0
    const DoctorAppointmentsScreen(),      // Index 1
    const DoctorPatientsListScreen(),      // Index 2
    const ProfileScreen(),                 // Index 3
  ];

  // No need for _fetchDoctorDetails for nickname here if DoctorHomeTab handles its own AppBar title

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
              onPressed: () async {
                await _auth.signOut();
                Navigator.of(context).pop(true); // Pop with confirmation
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
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
              (route) => false
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatbotScreen()));
        },
        backgroundColor: AppColors.secondary, // Highlight color
        foregroundColor: AppColors.primary,   // Icon color
        elevation: 4.0,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Adjust if your logo is too large/small
          child: Image.asset(
            'assets/logo.png', // <<-- REPLACE WITH YOUR CUREAI LOGO ASSET PATH
            errorBuilder: (context, error, stackTrace) { // Fallback icon
              return const Icon(Icons.insights_rounded, size: 30, color: AppColors.primary);
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.white,
        elevation: 8.0, // Add some elevation
        child: SizedBox(
          height: 65, // Adjusted height for better touch targets and aesthetics
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildDoctorBottomNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', index: 0),
              _buildDoctorBottomNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Bookings', index: 1),
              const SizedBox(width: 48), // The space for the FAB, adjust width as needed
              _buildDoctorBottomNavItem(icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt, label: 'Patients', index: 2),
              _buildDoctorBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorBottomNavItem({
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
        borderRadius: BorderRadius.circular(20), // For consistent splash effect
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primary : AppColors.gray, size: 26), // Slightly larger icon
            const SizedBox(height: 3), // Adjusted spacing
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.gray,
                fontSize: 11, // Slightly larger font
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DoctorHomeTab (ensure this widget and its dependencies are correctly defined) ---
class DoctorHomeTab extends StatefulWidget {
  const DoctorHomeTab({super.key});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  String? _doctorNickname;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetailsForAppBar();
  }

  Future<void> _fetchDoctorDetailsForAppBar() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _doctorNickname = (userDoc.data() as Map<String,dynamic>)['nickname'] as String?;
        });
      }
    }
  }

  // Re-use the logout confirmation from the main dashboard state if preferred,
  // or keep it local if DoctorHomeTab might be used elsewhere.
  // For this example, assuming it uses the same pattern:
  Future<void> _confirmLogoutDoctorHome() async {
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
              onPressed: () async {
                await _auth.signOut();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
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
              (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Not logged in."));

    final todayStart = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final todayEnd = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59));

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _doctorNickname != null ? 'Dr. $_doctorNickname\'s Dashboard' : 'Dashboard',
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: _confirmLogoutDoctorHome,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(currentUser.uid),
            const SizedBox(height: 24),
            Text("Today's Appointments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: currentUser.uid)
                  .where('date', isGreaterThanOrEqualTo: todayStart)
                  .where('date', isLessThanOrEqualTo: todayEnd)
                  .where('status', whereIn: ['scheduled', 'rescheduled']) // Add other active statuses if necessary
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("No appointments scheduled for today.", style: TextStyle(fontSize: 16, color: AppColors.gray))),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final appointment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final patientName = appointment['patientName'] ?? 'N/A';
                    final appointmentTime = (appointment['date'] as Timestamp).toDate();
                    final timeSlot = appointment['timeSlot'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.secondary, child: const Icon(Icons.person_pin_circle, color: AppColors.white)),
                        title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Time: ${DateFormat('h:mm a').format(appointmentTime)} (Slot: $timeSlot)',
                          style: TextStyle(color: AppColors.dark.withOpacity(0.7)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                        onTap: () {
                          // TODO: Navigate to appointment detail or patient chat for this doctor
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Tapped on ${patientName}'s appointment (Not Implemented)")),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(String doctorId) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('doctorId', isEqualTo: doctorId)
                      .where('status', whereIn: ['scheduled', 'rescheduled']) // Consider 'active', 'ongoing' too
                      .where('date', isGreaterThanOrEqualTo: Timestamp.now())
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildStatItem("Upcoming", "...", Icons.event, AppColors.success);
                    }
                    if (snapshot.hasError) {
                      debugPrint("Error fetching upcoming appointments stat: ${snapshot.error}");
                      return _buildStatItem("Upcoming", "Error", Icons.error_outline, AppColors.error);
                    }
                    return _buildStatItem("Upcoming", snapshot.hasData ? snapshot.data!.docs.length.toString() : "0", Icons.event, AppColors.success);
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('appointments')
                      .where('doctorId', isEqualTo: doctorId)
                  // .where('status', isEqualTo: 'completed') // To count only treated/completed patients
                      .snapshots(),
                  builder: (context, snapshot) {
                    Set<String> patientIds = {};
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data != null && data.containsKey('patientId')) {
                          patientIds.add(data['patientId'] as String);
                        }
                      }
                    }
                    if (snapshot.hasError) {
                      debugPrint("Error fetching total patients stat: ${snapshot.error}");
                      return _buildStatItem("Total Patients", "Error", Icons.people_alt, AppColors.secondary);
                    }
                    return _buildStatItem("Total Patients", patientIds.length.toString(), Icons.people_alt, AppColors.secondary);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28, // Slightly larger
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 30), // Slightly larger
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark)), // Larger value
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
      ],
    );
  }
}