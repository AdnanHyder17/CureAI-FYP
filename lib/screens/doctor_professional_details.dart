// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'homeScreen.dart';
// import 'package:p1/theme.dart';
//
// class DoctorProfessionalDetails extends StatefulWidget {
//   const DoctorProfessionalDetails({super.key});
//
//   @override
//   _DoctorProfessionalDetailsState createState() => _DoctorProfessionalDetailsState();
// }
//
// class _DoctorProfessionalDetailsState extends State<DoctorProfessionalDetails> {
//   final _formKey = GlobalKey<FormState>();
//   String _specialty = '';
//   String _qualifications = '';
//   int _yearsOfExperience = 0;
//   String _licenseNumber = '';
//   String _affiliatedInstitutions = '';
//   bool _isSubmitting = false;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> _saveData() async {
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//
//     setState(() => _isSubmitting = true);
//     _formKey.currentState?.save();
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception('User not authenticated');
//
//       await _firestore.collection('doctors').doc(user.uid).set({
//         'specialty': _specialty,
//         'qualifications': _qualifications,
//         'yearsOfExperience': _yearsOfExperience,
//         'licenseNumber': _licenseNumber,
//         'affiliatedInstitutions': _affiliatedInstitutions,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//             (Route<dynamic> route) => false,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     } finally {
//       if(mounted) setState(() => _isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Professional Details',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             color: AppColors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         centerTitle: true,
//       ),
//       body: _isSubmitting
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Submitting your details...',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: AppColors.dark,
//               ),
//             ),
//           ],
//         ),
//       )
//           : SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildInputField(
//                 label: 'Medical Specialty',
//                 hint: 'e.g., Cardiology, Pediatrics',
//                 icon: Icons.medical_services,
//                 validator: (v) => v!.isEmpty ? 'Please enter your specialty' : null,
//                 onSaved: (v) => _specialty = v!,
//               ),
//               const SizedBox(height: 16),
//               _buildInputField(
//                 label: 'Qualifications',
//                 hint: 'e.g., MD, MBBS, PhD',
//                 icon: Icons.school,
//                 validator: (v) => v!.isEmpty ? 'Please enter qualifications' : null,
//                 onSaved: (v) => _qualifications = v!,
//               ),
//               const SizedBox(height: 16),
//               _buildInputField(
//                 label: 'Years of Experience',
//                 hint: 'e.g., 5',
//                 icon: Icons.work_history,
//                 keyboard: TextInputType.number,
//                 validator: (v) {
//                   if (v!.isEmpty) return 'Please enter years of experience';
//                   if (int.tryParse(v) == null) return 'Invalid number';
//                   return null;
//                 },
//                 onSaved: (v) => _yearsOfExperience = int.parse(v!),
//               ),
//               const SizedBox(height: 16),
//               _buildInputField(
//                 label: 'License Number',
//                 hint: 'Your medical license number',
//                 icon: Icons.verified,
//                 validator: (v) => v!.isEmpty ? 'Please enter license number' : null,
//                 onSaved: (v) => _licenseNumber = v!,
//               ),
//               const SizedBox(height: 16),
//               _buildInputField(
//                 label: 'Affiliated Institutions',
//                 hint: 'e.g., XYZ Hospital, ABC Clinic',
//                 icon: Icons.business,
//                 onSaved: (v) => _affiliatedInstitutions = v ?? '',
//               ),
//               const SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: _isSubmitting ? null : _saveData,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: AppColors.white,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   elevation: 2,
//                 ),
//                 child: Text(
//                   'Submit',
//                   style: Theme.of(context).textTheme.labelLarge,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboard,
//     String? Function(String?)? validator,
//     void Function(String?)? onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         prefixIcon: Icon(icon, color: AppColors.secondary),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.gray),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.primary, width: 2),
//         ),
//         labelStyle: TextStyle(color: AppColors.dark),
//         hintStyle: TextStyle(color: AppColors.gray),
//       ),
//       keyboardType: keyboard,
//       validator: validator,
//       onSaved: onSaved,
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:intl/intl.dart';
// import 'homeScreen.dart';
// import 'package:p1/theme.dart';
//
// class DoctorProfessionalDetails extends StatefulWidget {
//   const DoctorProfessionalDetails({super.key});
//
//   @override
//   _DoctorProfessionalDetailsState createState() => _DoctorProfessionalDetailsState();
// }
//
// class _DoctorProfessionalDetailsState extends State<DoctorProfessionalDetails> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _scrollController = ScrollController();
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   // Form fields
//   String _specialty = '';
//   String _qualifications = '';
//   int _yearsOfExperience = 0;
//   String _licenseNumber = '';
//   String _affiliatedInstitutions = '';
//   String _bio = '';
//   double _consultationFee = 0.0;
//   File? _profileImage;
//   Map<String, List<TimeOfDay>> _availability = {
//     'Monday': [], 'Tuesday': [], 'Wednesday': [],
//     'Thursday': [], 'Friday': [], 'Saturday': [], 'Sunday': []
//   };
//
//   bool _isSubmitting = false;
//   final _specialties = [
//     'Cardiology', 'Dermatology', 'Endocrinology', 'Gastroenterology',
//     'Neurology', 'Oncology', 'Pediatrics', 'Psychiatry', 'Orthopedics'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//
//     if (image != null) {
//       setState(() => _profileImage = File(image.path));
//     }
//   }
//
//   Future<String?> _uploadImage() async {
//     if (_profileImage == null) return null;
//
//     final user = FirebaseAuth.instance.currentUser;
//     final storageRef = FirebaseStorage.instance
//         .ref()
//         .child('doctor_profiles')
//         .child('${user!.uid}.jpg');
//
//     await storageRef.putFile(_profileImage!);
//     return await storageRef.getDownloadURL();
//   }
//
//   void _showAvailabilityDialog(String day) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Set $day Availability'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   final TimeOfDay? start = await showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.now(),
//                   );
//                   if (start != null) {
//                     final TimeOfDay? end = await showTimePicker(
//                       context: context,
//                       initialTime: TimeOfDay.now(),
//                     );
//                     if (end != null) {
//                       setState(() {
//                         _availability[day]!.add(start);
//                         _availability[day]!.add(end);
//                       });
//                     }
//                   }
//                 },
//                 child: Text('Add Time Slot'),
//               ),
//               ..._availability[day]!.map((time) =>
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: Text(time.format(context)),
//                   ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Done'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _saveData() async {
//     if (!(_formKey.currentState?.validate() ?? false)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please check all required fields')),
//       );
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//     _formKey.currentState?.save();
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) throw Exception('User not authenticated');
//
//       final imageUrl = await _uploadImage();
//
//       // Convert availability times to a storable format
//       final availabilityMap = _availability.map((day, times) {
//         return MapEntry(day, times.map((time) =>
//         '${time.hour}:${time.minute}'
//         ).toList());
//       });
//
//       await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
//         'specialty': _specialty,
//         'qualifications': _qualifications,
//         'yearsOfExperience': _yearsOfExperience,
//         'licenseNumber': _licenseNumber,
//         'affiliatedInstitutions': _affiliatedInstitutions,
//         'bio': _bio,
//         'consultationFee': _consultationFee,
//         'profileImage': imageUrl,
//         'availability': availabilityMap,
//         'rating': 0.0,
//         'totalReviews': 0,
//         'status': 'active',
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//             (Route<dynamic> route) => false,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     } finally {
//       if(mounted) setState(() => _isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Professional Details',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             color: AppColors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: _isSubmitting
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Submitting your details...',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//           ],
//         ),
//       )
//           : FadeTransition(
//         opacity: _fadeAnimation,
//         child: SingleChildScrollView(
//           controller: _scrollController,
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: GestureDetector(
//                     onTap: _pickImage,
//                     child: Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: AppColors.secondary.withOpacity(0.2),
//                           backgroundImage: _profileImage != null
//                               ? FileImage(_profileImage!)
//                               : null,
//                           child: _profileImage == null
//                               ? Icon(Icons.camera_alt,
//                               size: 40,
//                               color: AppColors.secondary)
//                               : null,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: AppColors.primary,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               Icons.edit,
//                               size: 20,
//                               color: AppColors.white,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 DropdownButtonFormField<String>(
//                   decoration: _getInputDecoration(
//                     'Medical Specialty',
//                     Icons.medical_services,
//                   ),
//                   items: _specialties.map((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                   onChanged: (val) => setState(() => _specialty = val!),
//                   validator: (v) => v == null ? 'Please select specialty' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'Qualifications',
//                     Icons.school,
//                     'e.g., MD, MBBS, PhD',
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                   onSaved: (v) => _qualifications = v!,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'Years of Experience',
//                     Icons.work_history,
//                     'e.g., 5',
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (v) {
//                     if (v!.isEmpty) return 'Required';
//                     if (int.tryParse(v) == null) return 'Invalid number';
//                     return null;
//                   },
//                   onSaved: (v) => _yearsOfExperience = int.parse(v!),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'License Number',
//                     Icons.verified,
//                     'Your medical license number',
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Required' : null,
//                   onSaved: (v) => _licenseNumber = v!,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'Consultation Fee',
//                     Icons.attach_money,
//                     'e.g., 100.00',
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: (v) {
//                     if (v!.isEmpty) return 'Required';
//                     if (double.tryParse(v) == null) return 'Invalid amount';
//                     return null;
//                   },
//                   onSaved: (v) => _consultationFee = double.parse(v!),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'Bio',
//                     Icons.person,
//                     'Tell us about yourself and your practice',
//                   ),
//                   maxLines: 3,
//                   onSaved: (v) => _bio = v ?? '',
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   decoration: _getInputDecoration(
//                     'Affiliated Institutions',
//                     Icons.business,
//                     'e.g., XYZ Hospital, ABC Clinic',
//                   ),
//                   onSaved: (v) => _affiliatedInstitutions = v ?? '',
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   'Availability Schedule',
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _availability.keys.map((day) {
//                     return ActionChip(
//                       label: Text(day),
//                       onPressed: () => _showAvailabilityDialog(day),
//                       avatar: Icon(
//                         _availability[day]!.isEmpty
//                             ? Icons.access_time
//                             : Icons.check_circle,
//                         size: 18,
//                       ),
//                       backgroundColor: _availability[day]!.isEmpty
//                           ? AppColors.gray.withOpacity(0.2)
//                           : AppColors.secondary.withOpacity(0.2),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton(
//                   onPressed: _isSubmitting ? null : _saveData,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     foregroundColor: AppColors.white,
//                     minimumSize: const Size(double.infinity, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 2,
//                   ),
//                   child: Text(
//                     'Submit Details',
//                     style: Theme.of(context).textTheme.labelLarge,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   InputDecoration _getInputDecoration(String label, IconData icon, [String? hint]) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: Icon(icon, color: AppColors.secondary),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: AppColors.gray),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: AppColors.primary, width: 2),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: AppColors.gray.withOpacity(0.5)),
//       ),
//       filled: true,
//       fillColor: AppColors.white,
//       labelStyle: TextStyle(color: AppColors.dark),
//       hintStyle: TextStyle(color: AppColors.gray),
//     );
//   }
// }


// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

// doctor_professional_details.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:p1/theme.dart';
import 'homeScreen.dart';

class DoctorProfessionalDetails extends StatefulWidget {
  const DoctorProfessionalDetails({super.key});

  @override
  _DoctorProfessionalDetailsState createState() => _DoctorProfessionalDetailsState();
}

class _DoctorProfessionalDetailsState extends State<DoctorProfessionalDetails> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  File? _profileImage;
  String _specialty = '';
  String _qualifications = '';
  int _yearsOfExperience = 0;
  String _licenseNumber = '';
  String _affiliatedInstitutions = '';
  double _consultationFee = 0.0;
  final List<String> _languages = [];
  final Map<String, List<TimeOfDay>> _availability = {
    'Monday': [], 'Tuesday': [], 'Wednesday': [],
    'Thursday': [], 'Friday': [], 'Saturday': [], 'Sunday': []
  };
  String _about = '';
  bool _isSubmitting = false;

  final List<String> _specialties = [
    'Cardiology', 'Dermatology', 'Endocrinology', 'Family Medicine',
    'Gastroenterology', 'Neurology', 'Obstetrics', 'Pediatrics',
    'Psychiatry', 'Orthopedics'
  ];

  final List<String> _availableLanguages = [
    'English', 'Spanish', 'French', 'German', 'Chinese', 'Arabic', 'Hindi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold
            )),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSubmitting
          ? _buildLoadingIndicator()
          : _buildForm(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
          const SizedBox(height: 20),
          Text(
            'Submitting your details...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImagePicker(),
            const SizedBox(height: 24),
            _buildSpecialtyDropdown(),
            const SizedBox(height: 16),
            _buildQualificationsInput(),
            const SizedBox(height: 16),
            _buildExperienceInput(),
            const SizedBox(height: 16),
            _buildLicenseInput(),
            const SizedBox(height: 16),
            _buildInstitutionsInput(),
            const SizedBox(height: 16),
            _buildConsultationFeeInput(),
            const SizedBox(height: 16),
            _buildLanguagesSelection(),
            const SizedBox(height: 16),
            _buildAvailabilitySection(),
            const SizedBox(height: 16),
            _buildAboutInput(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              image: _profileImage != null
                  ? DecorationImage(
                image: FileImage(_profileImage!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _profileImage == null
                ? Icon(Icons.person,
                size: 60, color: AppColors.primary.withOpacity(0.5))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: IconButton(
                icon: Icon(Icons.camera_alt, size: 18, color: AppColors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _getInputDecoration(
        'Medical Specialty',
        'Select your specialty',
        Icons.medical_services,
      ),
      items: _specialties.map((String specialty) {
        return DropdownMenuItem(
          value: specialty,
          child: Text(specialty),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() => _specialty = newValue!);
      },
      validator: (value) =>
      value == null ? 'Please select your specialty' : null,
    );
  }

  Widget _buildLanguagesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages Spoken',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((language) {
            final isSelected = _languages.contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _languages.add(language);
                  } else {
                    _languages.remove(language);
                  }
                });
              },
              selectedColor: AppColors.secondary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Availability Schedule',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ..._availability.entries.map((entry) {
              return _buildDayAvailability(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAvailability(String day, List<TimeOfDay> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: Icon(Icons.add, color: AppColors.primary),
              label: Text('Add Slot',
                  style: TextStyle(color: AppColors.primary)),
              onPressed: () => _addTimeSlot(day),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: slots.map((time) {
            return Chip(
              label: Text(time.format(context)),
              onDeleted: () => _removeTimeSlot(day, time),
              deleteIconColor: AppColors.error,
            );
          }).toList(),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _addTimeSlot(String day) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _availability[day]!.add(time);
        _availability[day]!.sort((a, b) =>
        a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTimeSlot(String day, TimeOfDay time) {
    setState(() {
      _availability[day]!.remove(time);
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_profileImage == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('doctor_profiles')
        .child('${user.uid}.jpg');

    try {
      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one language')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String? profileImageUrl = await _uploadImage();

      // Convert TimeOfDay to string for storage
      Map<String, List<String>> availabilityStr = {};
      _availability.forEach((day, slots) {
        availabilityStr[day] = slots
            .map((time) => '${time.hour}:${time.minute}')
            .toList();
      });

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set({
        'profileImageUrl': profileImageUrl,
        'specialty': _specialty,
        'qualifications': _qualifications,
        'yearsOfExperience': _yearsOfExperience,
        'licenseNumber': _licenseNumber,
        'affiliatedInstitutions': _affiliatedInstitutions,
        'consultationFee': _consultationFee,
        'languages': _languages,
        'availability': availabilityStr,
        'about': _about,
        'rating': 0.0,
        'totalReviews': 0,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _getInputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.gray),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  Widget _buildQualificationsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: _getInputDecoration(
            'Qualifications',
            'e.g., MBBS, MD, MS',
            Icons.school,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your qualifications';
            }
            return null;
          },
          onSaved: (value) => _qualifications = value!,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your highest medical qualifications',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildExperienceInput() {
    return TextFormField(
      decoration: _getInputDecoration(
        'Years of Experience',
        'Enter total years of practice',
        Icons.work_history,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter years of experience';
        }
        final years = int.tryParse(value);
        if (years == null) {
          return 'Please enter a valid number';
        }
        if (years < 0 || years > 60) {
          return 'Please enter a valid number of years (0-60)';
        }
        return null;
      },
      onSaved: (value) => _yearsOfExperience = int.parse(value!),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildLicenseInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: _getInputDecoration(
            'Medical License Number',
            'Enter your medical license/registration number',
            Icons.verified,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your license number';
            }
            if (value.length < 5) {
              return 'License number seems too short';
            }
            return null;
          },
          onSaved: (value) => _licenseNumber = value!,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 4),
        Text(
          'This will be verified before account approval',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildInstitutionsInput() {
    return TextFormField(
      decoration: _getInputDecoration(
        'Affiliated Institutions',
        'e.g., City Hospital, Medical Center',
        Icons.business,
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter at least one institution';
        }
        return null;
      },
      onSaved: (value) => _affiliatedInstitutions = value!,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConsultationFeeInput() {
    return TextFormField(
      decoration: _getInputDecoration(
        'Consultation Fee',
        'Enter your fee per consultation',
        Icons.add_circle_outline,
      ).copyWith(
        prefixText: 'Rs ',
        suffixText: 'per consultation',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter consultation fee';
        }
        final fee = double.tryParse(value);
        if (fee == null) {
          return 'Please enter a valid amount';
        }
        if (fee < 0) {
          return 'Fee cannot be negative';
        }
        if (fee > 10000) {
          return 'Fee seems too high, please verify';
        }
        return null;
      },
      onSaved: (value) => _consultationFee = double.parse(value!),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildAboutInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: _getInputDecoration(
            '',
            'Tell us about your experience, specializations, and approach to patient care...',
            Icons.person_outline,
          ).copyWith(
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.all(16),
          ),
          maxLines: 5,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please write something about yourself';
            }
            if (value.length < 100) {
              return 'Please write at least 100 characters';
            }
            return null;
          },
          onSaved: (value) => _about = value!,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _saveData,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.white.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: _isSubmitting
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        )
            : Text(
          'Submit Details',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

