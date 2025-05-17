// lib/screens/profile_screen.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:p1/theme.dart';
import 'package:p1/widgets/custom_textfield.dart'; // Assuming your CustomTextField
import 'package:p1/widgets/loading_indicator.dart'; // Assuming your LoadingIndicator

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String _userRole = '';
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _profileData = {}; // Role-specific data
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Common Controllers
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Display only
  final TextEditingController _countryController = TextEditingController();

  // Doctor Specific Controllers
  String? _selectedDoctorSpecialty; // For Dropdown
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _affiliatedInstitutionsController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _aboutDoctorController = TextEditingController();
  List<String> _selectedDoctorLanguages = []; // For FilterChips

  // Patient Specific Controllers (Simplified for profile editing)
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController(); // Patient gender
  // Simplified text fields for patient health summary in profile edit
  final TextEditingController _patientMedicalSummaryController = TextEditingController();
  final TextEditingController _patientLifestyleSummaryController = TextEditingController();


  // Predefined lists (can be moved to a constants file)
  final List<String> _doctorSpecialtiesList = [
    'Cardiology', 'Dermatology', 'Endocrinology', 'Family Medicine', 'Gastroenterology',
    'Neurology', 'Obstetrics & Gynecology', 'Pediatrics', 'Psychiatry', 'Orthopedics',
    'Ophthalmology', 'Pulmonology', 'Urology', 'Other'
  ];
  final List<String> _availableLanguagesList = [
    'English', 'Spanish', 'French', 'German', 'Chinese (Mandarin)', 'Arabic', 'Hindi', 'Urdu', 'Portuguese', 'Russian', 'Japanese', 'Swahili'
  ];
  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say', 'Other'];


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _qualificationsController.dispose();
    _yearsOfExperienceController.dispose();
    _licenseNumberController.dispose();
    _affiliatedInstitutionsController.dispose();
    _consultationFeeController.dispose();
    _aboutDoctorController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _patientMedicalSummaryController.dispose();
    _patientLifestyleSummaryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    debugPrint("[ProfileScreen] Loading user data...");
    setState(() => _isLoading = true);
    final User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("[ProfileScreen] User not logged in.");
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        _userRole = _userData['role'] ?? '';
        debugPrint("[ProfileScreen] User data from 'users': $_userData");

        _nicknameController.text = _userData['nickname'] ?? '';
        _emailController.text = _userData['email'] ?? '';
        _countryController.text = _userData['country'] ?? '';

        if (_userRole == 'Doctor') {
          DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
          if (mounted && doctorDoc.exists) {
            _profileData = doctorDoc.data() as Map<String, dynamic>;
            debugPrint("[ProfileScreen] Doctor data from 'doctors': $_profileData");
            _selectedDoctorSpecialty = _profileData['specialty'];
            _qualificationsController.text = _profileData['qualifications'] ?? '';
            _yearsOfExperienceController.text = (_profileData['yearsOfExperience'] ?? '').toString();
            _licenseNumberController.text = _profileData['licenseNumber'] ?? '';
            _affiliatedInstitutionsController.text = _profileData['affiliatedInstitutions'] ?? '';
            _consultationFeeController.text = (_profileData['consultationFee']?.toStringAsFixed(0) ?? '');
            _aboutDoctorController.text = _profileData['about'] ?? '';
            _selectedDoctorLanguages = List<String>.from(_profileData['languages'] ?? []);
          }
        } else if (_userRole == 'Patient') {
          DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(user.uid).get();
          if (mounted && patientDoc.exists) {
            _profileData = patientDoc.data() as Map<String, dynamic>;
            debugPrint("[ProfileScreen] Patient data from 'patients': $_profileData");
            _ageController.text = (_profileData['basicInfo']?['age'] ?? _profileData['age'] ?? '').toString(); // Handle both structures
            _genderController.text = _profileData['basicInfo']?['gender'] ?? _profileData['gender'] ?? '';

            // Populate summary fields (these are for display/simple edit, full details in questionnaire)
            final healthProfile = _profileData['healthProfile'] as Map<String, dynamic>? ?? {};
            _patientMedicalSummaryController.text = [
              (healthProfile['chronicConditionsSelected'] as List<dynamic>? ?? []).join(', '),
              healthProfile['chronicConditionsOther'],
              (healthProfile['allergiesDetails'] ?? ''),
              (healthProfile['surgicalHistoryDetails'] ?? ''),
              (healthProfile['currentMedicationsDetails'] ?? '')
            ].where((s) => s != null && s.isNotEmpty).join('; ');


            final lifestyleHabits = _profileData['lifestyleHabits'] as Map<String, dynamic>? ?? {};
            _patientLifestyleSummaryController.text = [
              lifestyleHabits['smokingStatus'],
              lifestyleHabits['alcoholConsumption'],
              lifestyleHabits['physicalActivityLevel'],
              lifestyleHabits['sleepDuration'],
              lifestyleHabits['stressLevel']
            ].where((s) => s != null && s.isNotEmpty).join('; ');

          }
        }
      } else {
        debugPrint("[ProfileScreen] User document not found in 'users' collection.");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User data not found.'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      debugPrint("[ProfileScreen] Error loading user data: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024, maxHeight: 1024);
      if (pickedFile != null) {
        if (mounted) setState(() => _imageFile = File(pickedFile.path));
        debugPrint("[ProfileScreen] Image picked: ${pickedFile.path}");
      } else {
        debugPrint("[ProfileScreen] Image picking cancelled.");
      }
    } catch (e) {
      debugPrint("[ProfileScreen] Error picking image: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: ${e.toString()}"), backgroundColor: AppColors.error));
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      debugPrint("[ProfileScreen _uploadImage] No new image file selected. Returning existing URL if any.");
      return _userData['profileImageUrl'] as String?; // Return existing URL from 'users' collection
    }
    final User? user = _auth.currentUser;
    if (user == null) {
      debugPrint("[ProfileScreen _uploadImage] User not logged in. Cannot upload.");
      return null;
    }

    // Using a consistent name for the profile image to overwrite.
    // Alternatively, use a unique name if you want to keep old images, but then you need to manage deletion.
    final String imagePath = 'profile_images/${user.uid}/profile.jpg';
    final storageRef = _storage.ref().child(imagePath);
    debugPrint("[ProfileScreen _uploadImage] Attempting to upload to: $imagePath");

    try {
      UploadTask uploadTask = storageRef.putFile(
        _imageFile!,
        SettableMetadata(contentType: 'image/jpeg'), // Specify content type
      );

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      debugPrint("[ProfileScreen _uploadImage] UploadTask state: ${snapshot.state}");

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint("[ProfileScreen _uploadImage] Image uploaded successfully. URL: $downloadUrl");
        return downloadUrl;
      } else {
        debugPrint("[ProfileScreen _uploadImage] Image upload failed. State: ${snapshot.state}, Error: ${snapshot.storage.bucket}"); // More error info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed. Firebase state: ${snapshot.state}'), backgroundColor: AppColors.error),
          );
        }
        return _userData['profileImageUrl'] as String?; // Return old URL on failure
      }
    } catch (e) {
      debugPrint("[ProfileScreen _uploadImage] Exception during image upload: $e");
      if (e is FirebaseException && e.code == 'object-not-found') {
        debugPrint("[ProfileScreen _uploadImage] 'object-not-found' specifically caught. This is unusual after a putFile if the path is new or correctly overwritten. Possible causes: incorrect path used for getDownloadURL vs putFile, or permissions issue.");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
      return _userData['profileImageUrl'] as String?; // Return old URL on failure
    }
  }


  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.'), backgroundColor: AppColors.error),
      );
      return;
    }
    _formKey.currentState!.save();
    debugPrint("[ProfileScreen] Saving changes...");
    setState(() => _isSaving = true);

    final User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isSaving = false);
      debugPrint("[ProfileScreen] User not logged in. Cannot save.");
      return;
    }

    try {
      final String? newProfileImageUrl = await _uploadImage(); // This will return existing if _imageFile is null

      Map<String, dynamic> userDataToUpdate = {
        'nickname': _nicknameController.text.trim(),
        'nickname_lowercase': _nicknameController.text.trim().toLowerCase(),
        'country': _countryController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (newProfileImageUrl != null) 'profileImageUrl': newProfileImageUrl,
      };
      // If newProfileImageUrl is null AND _imageFile was null, it means we keep the existing one (implicitly not changing it in Firestore if not in map).
      // If newProfileImageUrl is null because upload failed but _imageFile was not null, we don't update the URL.
      // If _imageFile was null, _uploadImage returns existing URL, so it's fine to include it if not null.


      await _firestore.collection('users').doc(user.uid).set(userDataToUpdate, SetOptions(merge: true));
      debugPrint("[ProfileScreen] Updated 'users' collection.");

      if (_userRole == 'Doctor') {
        Map<String, dynamic> doctorDataToUpdate = {
          'nickname': _nicknameController.text.trim(),
          'nickname_lowercase': _nicknameController.text.trim().toLowerCase(),
          'specialty': _selectedDoctorSpecialty,
          'qualifications': _qualificationsController.text.trim(),
          'yearsOfExperience': int.tryParse(_yearsOfExperienceController.text.trim()) ?? _profileData['yearsOfExperience'] ?? 0,
          'licenseNumber': _licenseNumberController.text.trim(),
          'affiliatedInstitutions': _affiliatedInstitutionsController.text.trim(),
          'consultationFee': double.tryParse(_consultationFeeController.text.trim()) ?? _profileData['consultationFee'] ?? 0.0,
          'about': _aboutDoctorController.text.trim(),
          'languages': _selectedDoctorLanguages,
          'updatedAt': FieldValue.serverTimestamp(),
          if (newProfileImageUrl != null) 'profileImageUrl': newProfileImageUrl,
        };
        await _firestore.collection('doctors').doc(user.uid).set(doctorDataToUpdate, SetOptions(merge: true));
        debugPrint("[ProfileScreen] Updated 'doctors' collection.");
      } else if (_userRole == 'Patient') {
        Map<String, dynamic> patientDataToUpdate = {
          'basicInfo': { // Assuming you want to maintain this structure
            'age': int.tryParse(_ageController.text.trim()) ?? (_profileData['basicInfo']?['age'] ?? _profileData['age'] ?? 0),
            'gender': _genderController.text.trim().isNotEmpty ? _genderController.text.trim() : (_profileData['basicInfo']?['gender'] ?? _profileData['gender']),
          },
          // For simplified profile edit, we might just update a summary text or specific editable fields.
          // The complex healthProfile and lifestyleHabits are better managed via their dedicated questionnaire.
          // Here we update what's editable on this screen.
          // For demonstration, let's assume some simple fields are directly in 'patients' doc:
          'age': int.tryParse(_ageController.text.trim()) ?? (_profileData['age'] ?? 0), // Storing age directly too
          'gender': _genderController.text.trim().isNotEmpty ? _genderController.text.trim() : _profileData['gender'], // Storing gender directly too
          'medicalSummary': _patientMedicalSummaryController.text.trim(), // Example summary field
          'lifestyleSummary': _patientLifestyleSummaryController.text.trim(), // Example summary field
          'lastUpdated': FieldValue.serverTimestamp(),
          if (newProfileImageUrl != null) 'profileImageUrl': newProfileImageUrl,
        };
        await _firestore.collection('patients').doc(user.uid).set(patientDataToUpdate, SetOptions(merge: true));
        debugPrint("[ProfileScreen] Updated 'patients' collection.");
      }

      await _loadUserData(); // Refresh data on screen
      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint("[ProfileScreen] Error saving profile: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildProfileImageWidget() {
    final String? currentImageUrl = _userData['profileImageUrl'] as String?; // Prioritize 'users' doc for image
    debugPrint("[ProfileScreen _buildProfileImageWidget] Current Image URL: $currentImageUrl, _imageFile: ${_imageFile?.path}");

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
              color: AppColors.light.withOpacity(0.5), // Fallback background
            ),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover, width: 130, height: 130)
                  : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl: currentImageUrl,
                fit: BoxFit.cover, width: 130, height: 130,
                placeholder: (context, url) => const LoadingIndicator(size: 30),
                errorWidget: (context, url, error) {
                  debugPrint("[ProfileScreen] CachedNetworkImage error for URL $currentImageUrl: $error");
                  return Icon(Icons.person, size: 70, color: AppColors.primary.withOpacity(0.5));
                },
              )
                  : Icon(Icons.person, size: 70, color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
          if (_isEditing)
            MaterialButton(
              onPressed: _pickImage,
              color: AppColors.secondary, textColor: AppColors.white,
              padding: const EdgeInsets.all(8), shape: const CircleBorder(), elevation: 2.0,
              child: const Icon(Icons.camera_alt, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CustomTextField( // Using your CustomTextField
        controller: controller,
        labelText: label,
        prefixIcon: icon,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: enabled ? (validator ?? (value) { // Only validate if enabled
          if (value == null || value.isEmpty) return 'Please enter $label';
          return null;
        }) : null,
      ),
    );
  }

  Widget _buildDisplayField({required String label, required String value, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: AppColors.primary, size: 20),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 15, color: AppColors.dark.withOpacity(0.7), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  // --- Edit Forms ---
  Widget _buildDoctorEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Basic Information"),
        _buildTextField(controller: _nicknameController, label: "Nickname", icon: Icons.person_outline_rounded),
        _buildTextField(controller: _countryController, label: "Country", icon: Icons.flag_outlined),
        _buildTextField(controller: _emailController, label: "Email (Cannot Change)", icon: Icons.email_outlined, enabled: false),

        _buildSectionTitle("Professional Details"),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedDoctorSpecialty,
            decoration: InputDecoration(labelText: 'Medical Specialty *', prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.secondary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: _doctorSpecialtiesList.map((String specialty) => DropdownMenuItem(value: specialty, child: Text(specialty))).toList(),
            onChanged: (String? newValue) => setState(() => _selectedDoctorSpecialty = newValue),
            validator: (value) => value == null || value.isEmpty ? 'Please select specialty' : null,
          ),
        ),
        _buildTextField(controller: _qualificationsController, label: "Qualifications (e.g., MBBS, MD)", icon: Icons.school_outlined),
        _buildTextField(controller: _yearsOfExperienceController, label: "Years of Experience", icon: Icons.work_history_outlined, keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (int.tryParse(val) == null || int.parse(val) < 0 || int.parse(val) > 70) return 'Invalid (0-70)';
              return null;
            }),
        _buildTextField(controller: _licenseNumberController, label: "Medical License Number", icon: Icons.verified_user_outlined),
        _buildTextField(controller: _affiliatedInstitutionsController, label: "Affiliated Institutions", icon: Icons.business_outlined, validator: null), // Optional
        _buildTextField(controller: _consultationFeeController, label: "Consultation Fee (PKR)", icon: Icons.price_check_outlined, keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (double.tryParse(val) == null || double.parse(val) < 0 || double.parse(val) > 50000) return 'Invalid (0-50000)';
              return null;
            }),
        _buildTextField(controller: _aboutDoctorController, label: "About Yourself (Min 100 chars)", icon: Icons.info_outline_rounded, maxLines: 4,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please write something about yourself';
              if (val.length < 100) return 'Min 100 characters required';
              return null;
            }),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Languages Spoken *", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.dark.withOpacity(0.8))),
        ),
        Wrap(
          spacing: 8.0, runSpacing: 4.0,
          children: _availableLanguagesList.map((language) {
            final isSelected = _selectedDoctorLanguages.contains(language);
            return FilterChip(
              label: Text(language, style: TextStyle(color: isSelected ? AppColors.white : AppColors.primary)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedDoctorLanguages.contains(language)) _selectedDoctorLanguages.add(language);
                  } else {
                    _selectedDoctorLanguages.remove(language);
                  }
                });
              },
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              backgroundColor: AppColors.light,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.5))),
            );
          }).toList(),
        ),
        if (_selectedDoctorLanguages.isEmpty && _formKey.currentState != null && !_formKey.currentState!.validate()) // Show error if trying to save with no language
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Please select at least one language.", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),

      ],
    );
  }

  Widget _buildPatientEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Basic Information"),
        _buildTextField(controller: _nicknameController, label: "Nickname", icon: Icons.person_outline_rounded),
        _buildTextField(controller: _countryController, label: "Country", icon: Icons.flag_outlined),
        _buildTextField(controller: _emailController, label: "Email (Cannot Change)", icon: Icons.email_outlined, enabled: false),
        _buildTextField(controller: _ageController, label: "Age", icon: Icons.cake_outlined, keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              if (int.tryParse(val) == null || int.parse(val) <= 0 || int.parse(val) > 120) return 'Valid age (1-120)';
              return null;
            }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            // controller: _genderController, // Dropdown doesn't use controller directly for value
            value: _genderController.text.isNotEmpty && _genderOptions.contains(_genderController.text) ? _genderController.text : null,
            decoration: InputDecoration(labelText: 'Gender *', prefixIcon: Icon(Icons.wc_rounded, color: AppColors.secondary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: _genderOptions.map((String gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
            onChanged: (String? newValue) => setState(() {
              if(newValue != null) _genderController.text = newValue;
            }),
            validator: (value) => (value == null || value.isEmpty) ? 'Please select gender' : null,
          ),
        ),

        _buildSectionTitle("Health & Lifestyle Summary"),
        _buildTextField(controller: _patientMedicalSummaryController, label: "Medical Summary (Conditions, Allergies, Meds)", icon: Icons.medical_information_outlined, maxLines: 3, validator: null), // Optional
        _buildTextField(controller: _patientLifestyleSummaryController, label: "Lifestyle Summary (Diet, Activity, Sleep)", icon: Icons.spa_outlined, maxLines: 3, validator: null), // Optional
        Padding(
          padding: const EdgeInsets.only(top:12.0),
          child: Text("For detailed updates, please use the Health Questionnaire.", style: TextStyle(fontSize: 13, color: AppColors.gray, fontStyle: FontStyle.italic)),
        )
      ],
    );
  }

  // --- Display Views (Non-Editing) ---
  Widget _buildDoctorDisplayView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Basic Information"),
        _buildDisplayField(label: "Email", value: _userData['email'] ?? '', icon: Icons.email_outlined),
        _buildDisplayField(label: "Country", value: _userData['country'] ?? '', icon: Icons.flag_outlined),

        _buildSectionTitle("Professional Details"),
        _buildDisplayField(label: "Specialty", value: _profileData['specialty'] ?? 'N/A', icon: Icons.medical_services_outlined),
        _buildDisplayField(label: "Qualifications", value: _profileData['qualifications'] ?? 'N/A', icon: Icons.school_outlined),
        _buildDisplayField(label: "Experience", value: "${_profileData['yearsOfExperience'] ?? 0} years", icon: Icons.work_history_outlined),
        _buildDisplayField(label: "License No.", value: _profileData['licenseNumber'] ?? 'N/A', icon: Icons.verified_user_outlined),
        _buildDisplayField(label: "Affiliations", value: _profileData['affiliatedInstitutions'] ?? 'N/A', icon: Icons.business_outlined),
        _buildDisplayField(label: "Fee", value: "PKR ${_profileData['consultationFee']?.toStringAsFixed(0) ?? 'N/A'}", icon: Icons.price_check_outlined),
        _buildDisplayField(label: "Languages", value: (_profileData['languages'] as List<dynamic>?)?.join(', ') ?? 'N/A', icon: Icons.language_outlined),

        _buildSectionTitle("About Me"),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
          child: Text(_profileData['about'] ?? 'No information provided.', style: TextStyle(fontSize: 15, color: AppColors.dark.withOpacity(0.85), height: 1.45)),
        ),
      ],
    );
  }

  Widget _buildPatientDisplayView() {
    // Use a temporary variable from _profileData if basicInfo is nested
    final ageFromProfile = _profileData['basicInfo']?['age'] ?? _profileData['age'];
    final genderFromProfile = _profileData['basicInfo']?['gender'] ?? _profileData['gender'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Basic Information"),
        _buildDisplayField(label: "Email", value: _userData['email'] ?? '', icon: Icons.email_outlined),
        _buildDisplayField(label: "Country", value: _userData['country'] ?? '', icon: Icons.flag_outlined),
        _buildDisplayField(label: "Age", value: (ageFromProfile ?? 'N/A').toString(), icon: Icons.cake_outlined),
        _buildDisplayField(label: "Gender", value: (genderFromProfile ?? 'N/A').toString(), icon: Icons.wc_rounded),

        _buildSectionTitle("Health & Lifestyle Summary"),
        _buildDisplayField(label: "Medical Summary", value: _patientMedicalSummaryController.text.isNotEmpty ? _patientMedicalSummaryController.text : (_profileData['medicalSummary'] ?? 'Not specified'), icon: Icons.medical_information_outlined),
        _buildDisplayField(label: "Lifestyle Summary", value: _patientLifestyleSummaryController.text.isNotEmpty ? _patientLifestyleSummaryController.text : (_profileData['lifestyleSummary'] ?? 'Not specified'), icon: Icons.spa_outlined),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            "Note: This is a summary. For detailed health information or updates, please fill out the complete Health Questionnaire from the welcome screen if you haven't already.",
            style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.gray, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'My Profile', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white), // For back button if navigated to
        elevation: 2,
        leading: _isEditing ? IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () {
            setState(() {
              _isEditing = false;
              _imageFile = null;
              _loadUserData(); // Revert changes by reloading
            });
          },
        ) : null,
        actions: [
          if (!_isLoading && !_isSaving)
            _isEditing
                ? TextButton(
              onPressed: _saveChanges,
              child: const Text('SAVE', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            )
                : IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: "Edit Profile",
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SizedBox(width:20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: "Loading profile..."))
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileImageWidget(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isEditing ? _nicknameController.text : (_userData['nickname'] ?? 'User'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
                  ),
                ),
                Center(
                  child: Chip(
                    label: Text(_userRole, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500)),
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    avatar: Icon(_userRole == 'Doctor' ? Icons.medical_services_rounded : Icons.person_rounded, color: AppColors.secondary, size: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isEditing)
                  _userRole == 'Doctor' ? _buildDoctorEditForm() : _buildPatientEditForm()
                else
                  _userRole == 'Doctor' ? _buildDoctorDisplayView() : _buildPatientDisplayView(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}