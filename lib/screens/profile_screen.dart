import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  String _userRole = '';
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _profileData = {};
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers for common fields
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // Controllers for doctor fields
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _affiliatedInstitutionsController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();

  // Controllers for patient fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _chronicConditionsController = TextEditingController();
  final TextEditingController _currentMedicationsController = TextEditingController();
  final TextEditingController _familyHealthHistoryController = TextEditingController();
  final TextEditingController _knownAllergiesController = TextEditingController();
  final TextEditingController _medicationHistoryController = TextEditingController();
  final TextEditingController _physicalActivityLevelController = TextEditingController();
  final TextEditingController _sleepPatternController = TextEditingController();
  final TextEditingController _smokingIntensityController = TextEditingController();
  final TextEditingController _stressLevelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nicknameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _aboutController.dispose();
    _specialtyController.dispose();
    _qualificationsController.dispose();
    _affiliatedInstitutionsController.dispose();
    _licenseNumberController.dispose();
    _yearsOfExperienceController.dispose();
    _consultationFeeController.dispose();
    _languagesController.dispose();
    _ageController.dispose();
    _chronicConditionsController.dispose();
    _currentMedicationsController.dispose();
    _familyHealthHistoryController.dispose();
    _knownAllergiesController.dispose();
    _medicationHistoryController.dispose();
    _physicalActivityLevelController.dispose();
    _sleepPatternController.dispose();
    _smokingIntensityController.dispose();
    _stressLevelController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        // Get user basic info
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          _userData = userDoc.data() as Map<String, dynamic>;
          _userRole = _userData['role'] ?? '';

          // Set controllers for common fields
          _nicknameController.text = _userData['nickname'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _countryController.text = _userData['country'] ?? '';

          // Get role-specific data
          if (_userRole == 'Doctor') {
            final doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();
            if (doctorDoc.exists) {
              _profileData = doctorDoc.data() as Map<String, dynamic>;

              // Set controllers for doctor fields
              _aboutController.text = _profileData['about'] ?? '';
              _specialtyController.text = _profileData['specialty'] ?? '';
              _qualificationsController.text = _profileData['qualifications'] ?? '';
              _affiliatedInstitutionsController.text = _profileData['affiliatedInstitutions'] ?? '';
              _licenseNumberController.text = _profileData['licenseNumber'] ?? '';
              _yearsOfExperienceController.text = _profileData['yearsOfExperience']?.toString() ?? '';
              _consultationFeeController.text = _profileData['consultationFee']?.toString() ?? '';
              _languagesController.text = (_profileData['languages'] as List<dynamic>?)?.join(', ') ?? '';
            }
          } else if (_userRole == 'Patient') {
            final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
            if (patientDoc.exists) {
              _profileData = patientDoc.data() as Map<String, dynamic>;

              // Set controllers for patient fields
              _ageController.text = _profileData['age']?.toString() ?? '';
              _chronicConditionsController.text = _profileData['chronicConditions'] ?? '';
              _currentMedicationsController.text = _profileData['currentMedications'] ?? '';
              _familyHealthHistoryController.text = _profileData['familyHealthHistory'] ?? '';
              _knownAllergiesController.text = _profileData['knownAllergies'] ?? '';
              _medicationHistoryController.text = _profileData['medicationHistory'] ?? '';
              _physicalActivityLevelController.text = _profileData['physicalActivityLevel'] ?? '';
              _sleepPatternController.text = _profileData['sleepPattern'] ?? '';
              _smokingIntensityController.text = _profileData['smokingIntensity'] ?? '';
              _stressLevelController.text = _profileData['stressLevel'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final String uid = _auth.currentUser!.uid;
      final Reference storageRef = _storage.ref().child('profile_images').child('$uid.jpg');

      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String uid = _auth.currentUser!.uid;
      String? profileImageUrl;

      // Upload image if selected
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage();
      }

      // Update user data in 'users' collection
      await _firestore.collection('users').doc(uid).update({
        'nickname': _nicknameController.text,
        'nickname_lowercase': _nicknameController.text.toLowerCase(),
        'country': _countryController.text,
      });

      // Update role-specific data
      if (_userRole == 'Doctor') {
        final Map<String, dynamic> doctorData = {
          'nickname': _nicknameController.text,
          'nickname_lowercase': _nicknameController.text.toLowerCase(),
          'about': _aboutController.text,
          'specialty': _specialtyController.text,
          'qualifications': _qualificationsController.text,
          'affiliatedInstitutions': _affiliatedInstitutionsController.text,
          'licenseNumber': _licenseNumberController.text,
          'yearsOfExperience': int.tryParse(_yearsOfExperienceController.text) ?? 0,
          'consultationFee': int.tryParse(_consultationFeeController.text) ?? 0,
          'languages': _languagesController.text.split(',').map((e) => e.trim()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (profileImageUrl != null) {
          doctorData['profileImageUrl'] = profileImageUrl;
        } else if (_profileData.containsKey('profileImageUrl')) { // Retain existing image if not changed
          doctorData['profileImageUrl'] = _profileData['profileImageUrl'];
        }


        await _firestore.collection('doctors').doc(uid).update(doctorData);
      } else if (_userRole == 'Patient') {
        final Map<String, dynamic> patientData = {
          'age': int.tryParse(_ageController.text) ?? 0,
          'chronicConditions': _chronicConditionsController.text,
          'currentMedications': _currentMedicationsController.text,
          'familyHealthHistory': _familyHealthHistoryController.text,
          'knownAllergies': _knownAllergiesController.text,
          'medicationHistory': _medicationHistoryController.text,
          'physicalActivityLevel': _physicalActivityLevelController.text,
          'sleepPattern': _sleepPatternController.text,
          'smokingIntensity': _smokingIntensityController.text,
          'stressLevel': _stressLevelController.text,
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (profileImageUrl != null) {
          patientData['profileImageUrl'] = profileImageUrl;
        }

        await _firestore.collection('patients').doc(uid).update(patientData);
      }

      // Reload data to reflect changes
      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      setState(() {
        _isEditing = false;
        _imageFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    final String? profileImageUrl = _profileData['profileImageUrl'];
    final double imageSize = 120;

    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              )
                  : (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl: profileImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.person,
                  size: 80,
                  color: AppColors.gray,
                ),
              )
                  : const Icon(
                Icons.person,
                size: 80,
                color: AppColors.gray,
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        _buildTextField(
          controller: _nicknameController,
          label: 'Nickname',
          icon: Icons.person,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          enabled: false, // Email should not be editable
        ),
        _buildTextField(
          controller: _countryController,
          label: 'Country',
          icon: Icons.location_on,
          enabled: _isEditing,
        ),
      ],
    );
  }

  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Professional Information'),
        _buildTextField(
          controller: _specialtyController,
          label: 'Specialty',
          icon: Icons.medical_services,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _qualificationsController,
          label: 'Qualifications',
          icon: Icons.school,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _affiliatedInstitutionsController,
          label: 'Affiliated Institutions',
          icon: Icons.business,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _licenseNumberController,
          label: 'License Number',
          icon: Icons.badge,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _yearsOfExperienceController,
          label: 'Years of Experience',
          icon: Icons.timer,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _consultationFeeController,
          label: 'Consultation Fee',
          icon: Icons.attach_money,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _languagesController,
          label: 'Languages (comma separated)',
          icon: Icons.language,
          enabled: _isEditing,
        ),
        _buildSectionTitle('About Me'),
        _buildTextField(
          controller: _aboutController,
          label: 'About',
          icon: Icons.info,
          enabled: _isEditing,
          maxLines: 5,
        ),
        if (!_isEditing) ...[
          _buildSectionTitle('Statistics'),
          _buildInfoItem(
            label: 'Rating',
            value: '${_profileData['rating'] ?? 0} / 5',
            icon: Icons.star,
          ),
          _buildInfoItem(
            label: 'Total Reviews',
            value: '${_profileData['totalReviews'] ?? 0}',
            icon: Icons.reviews,
          ),
          _buildInfoItem(
            label: 'Status',
            value: '${_profileData['status'] ?? 'Offline'}',
            icon: Icons.circle,
            valueColor: _profileData['status'] == 'online' ? AppColors.success : AppColors.gray,
          ),
        ],
      ],
    );
  }

  Widget _buildPatientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Health Information'),
        _buildTextField(
          controller: _ageController,
          label: 'Age',
          icon: Icons.cake,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _physicalActivityLevelController,
          label: 'Physical Activity Level',
          icon: Icons.directions_run,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _sleepPatternController,
          label: 'Sleep Pattern',
          icon: Icons.nightlight,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _stressLevelController,
          label: 'Stress Level',
          icon: Icons.psychology,
          enabled: _isEditing,
        ),
        _buildTextField(
          controller: _smokingIntensityController,
          label: 'Smoking Intensity',
          icon: Icons.smoking_rooms,
          enabled: _isEditing,
        ),
        _buildSectionTitle('Medical History'),
        _buildTextField(
          controller: _chronicConditionsController,
          label: 'Chronic Conditions',
          icon: Icons.monitor_heart,
          enabled: _isEditing,
          maxLines: 3,
        ),
        _buildTextField(
          controller: _currentMedicationsController,
          label: 'Current Medications',
          icon: Icons.medication,
          enabled: _isEditing,
          maxLines: 3,
        ),
        _buildTextField(
          controller: _medicationHistoryController,
          label: 'Medication History',
          icon: Icons.history,
          enabled: _isEditing,
          maxLines: 3,
        ),
        _buildTextField(
          controller: _knownAllergiesController,
          label: 'Known Allergies',
          icon: Icons.dangerous,
          enabled: _isEditing,
          maxLines: 3,
        ),
        _buildTextField(
          controller: _familyHealthHistoryController,
          label: 'Family Health History',
          icon: Icons.people,
          enabled: _isEditing,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
          ),
          filled: true,
          fillColor: enabled ? AppColors.white : AppColors.light,
        ),
        style: TextStyle(
          color: enabled ? AppColors.dark : AppColors.gray,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    // Revert changes
                    _loadUserData();
                    _isEditing = false;
                    _imageFile = null;
                  } else {
                    _isEditing = true;
                  }
                });
              },
              color: AppColors.white,
            ),
          if (_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              color: AppColors.white,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture and Role
              Center(
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 12),
                    Text(
                      _userData['nickname'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userRole,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              _buildCommonFields(),

              // Role-specific fields
              if (_userRole == 'Doctor')
                _buildDoctorFields()
              else if (_userRole == 'Patient')
                _buildPatientFields(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}