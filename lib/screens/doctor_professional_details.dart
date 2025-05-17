// lib/screens/doctor_professional_details.dart
// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:p1/theme.dart';
import 'package:p1/screens/doctor_dashboard_screen.dart';
import 'package:p1/widgets/custom_textfield.dart'; // Assuming this is your custom widget
import 'package:p1/widgets/loading_indicator.dart'; // Assuming this is your custom widget
import 'package:intl/intl.dart'; // For formatting time
import 'package:p1/screens/login_screen.dart';

class DoctorProfessionalDetails extends StatefulWidget {
  const DoctorProfessionalDetails({super.key});

  @override
  _DoctorProfessionalDetailsState createState() =>
      _DoctorProfessionalDetailsState();
}

class _DoctorProfessionalDetailsState extends State<DoctorProfessionalDetails> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // --- State Variables ---
  File? _profileImageFile;
  String? _existingProfileImageUrl;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  // --- Form Controllers ---
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _affiliatedInstitutionsController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  Map<String, dynamic> _profileData = {}; // To store existing profile data from Firestore

  // --- Dropdown & Chips Data ---
  String? _selectedSpecialty; // Nullable for initial state
  final List<String> _specialtiesList = [
    'Cardiology', 'Dermatology', 'Endocrinology', 'Family Medicine',
    'Gastroenterology', 'Neurology', 'Obstetrics & Gynecology', 'Pediatrics',
    'Psychiatry', 'Orthopedics', 'Ophthalmology', 'Pulmonology', 'Urology', 'Other'
  ];
  final List<String> _selectedLanguages = [];
  final List<String> _availableLanguagesList = [
    'English', 'Spanish', 'French', 'German', 'Chinese (Mandarin)', 'Arabic', 'Hindi', 'Urdu', 'Portuguese', 'Russian', 'Japanese', 'Swahili'
  ];

  // --- Availability Data ---
  // Storing TimeOfDay for UI, will convert to "HH:mm" string for Firestore
  final Map<String, List<Map<String, TimeOfDay?>>> _availability = {
    'Monday': [], 'Tuesday': [], 'Wednesday': [], 'Thursday': [],
    'Friday': [], 'Saturday': [], 'Sunday': []
  };
  final List<String> _daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];


  @override
  void initState() {
    super.initState();
    _loadDoctorDataForEditing();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _qualificationsController.dispose();
    _yearsOfExperienceController.dispose();
    _licenseNumberController.dispose();
    _affiliatedInstitutionsController.dispose();
    _consultationFeeController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorDataForEditing() async {
    setState(() => _isLoadingData = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    try {
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();

      if (mounted && doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;

        _profileData = data;

        _existingProfileImageUrl = data['profileImageUrl'] as String?;
        _selectedSpecialty = data['specialty'] as String?;
        _qualificationsController.text = data['qualifications'] ?? '';
        _yearsOfExperienceController.text = (data['yearsOfExperience'] ?? '').toString();
        _licenseNumberController.text = data['licenseNumber'] ?? '';
        _affiliatedInstitutionsController.text = data['affiliatedInstitutions'] ?? '';
        _consultationFeeController.text = (data['consultationFee']?.toStringAsFixed(0) ?? '');
        _aboutController.text = data['about'] ?? '';

        if (data['languages'] is List) {
          _selectedLanguages.clear();
          _selectedLanguages.addAll(List<String>.from(data['languages']));
        }

        // Parse availability from Firestore string format to TimeOfDay
        _availability.updateAll((key, value) => []); // Clear existing UI state
        if (data['availability'] != null && data['availability'] is Map) {
          final Map<String, dynamic> availabilityFromDb = Map<String, dynamic>.from(data['availability']);
          availabilityFromDb.forEach((dayKey, dayRangesDynamic) {
            if (_availability.containsKey(dayKey) && dayRangesDynamic is List) {
              List<Map<String, TimeOfDay?>> daySlots = [];
              for (var rangeDynamic in dayRangesDynamic) {
                if (rangeDynamic is Map) {
                  final startStr = rangeDynamic['start'] as String?;
                  final endStr = rangeDynamic['end'] as String?;
                  TimeOfDay? startTime, endTime;

                  if (startStr != null && startStr.isNotEmpty) {
                    final parts = startStr.split(':');
                    if (parts.length == 2) startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                  }
                  if (endStr != null && endStr.isNotEmpty) {
                    final parts = endStr.split(':');
                    if (parts.length == 2) endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                  }
                  if (startTime != null && endTime != null) daySlots.add({'start': startTime, 'end': endTime});
                }
              }
              _availability[dayKey] = daySlots;
            }
          });
        }
      } else {
        _availability.updateAll((key, value) => []); // Ensure empty if no profile
      }
    } catch (e) {
      debugPrint("Error loading doctor data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile data: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
      _availability.updateAll((key, value) => []);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024, maxHeight: 1024);
      if (image != null) {
        if (mounted) setState(() => _profileImageFile = File(image.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: ${e.toString()}"), backgroundColor: AppColors.error));
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_profileImageFile == null) return _existingProfileImageUrl; // Return existing if no new file

    final storageRef = FirebaseStorage.instance.ref().child('doctor_profiles').child('$userId.jpg'); // Consistent naming
    try {
      // Delete existing image if overwriting, to save space (optional)
      // try { await storageRef.delete(); } catch (e) { debugPrint("No existing image to delete or error: $e"); }

      await storageRef.putFile(_profileImageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image: ${e.toString()}"), backgroundColor: AppColors.error));
      return _existingProfileImageUrl; // Fallback to existing on error
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.'), backgroundColor: AppColors.error),
      );
      // Scroll to the first error
      _formKey.currentState!.validate(); // This will mark fields with errors
      return;
    }
    if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your medical specialty.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language you speak.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated.');

      // Fetch doctor's nickname from 'users' collection
      final userDocSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String doctorNickname = userDocSnapshot.exists && userDocSnapshot.data()!.containsKey('nickname')
          ? userDocSnapshot.data()!['nickname'] as String
          : 'Dr. User'; // Fallback nickname

      final String? uploadedProfileImageUrl = await _uploadImage(user.uid);

      // Convert availability TimeOfDay to "HH:mm" string for Firestore
      Map<String, List<Map<String, String>>> availabilityForFirestore = {};
      _availability.forEach((day, ranges) {
        availabilityForFirestore[day] = ranges
            .where((range) => range['start'] != null && range['end'] != null)
            .map((range) {
          final start = range['start']!;
          final end = range['end']!;
          return {
            'start': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
            'end': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
          };
        }).toList();
      });

      Map<String, dynamic> doctorDataToSave = {
        'uid': user.uid, // Ensure UID is part of the doctor's document
        'email': user.email, // Denormalize email for easier querying if needed
        'nickname': doctorNickname,
        'nickname_lowercase': doctorNickname.toLowerCase(),
        'profileImageUrl': uploadedProfileImageUrl, // This will be null if no new image and no existing one, or URL
        'specialty': _selectedSpecialty,
        'specialty_lowercase': _selectedSpecialty?.toLowerCase(),
        'qualifications': _qualificationsController.text.trim(),
        'yearsOfExperience': int.tryParse(_yearsOfExperienceController.text.trim()) ?? 0,
        'licenseNumber': _licenseNumberController.text.trim(),
        'affiliatedInstitutions': _affiliatedInstitutionsController.text.trim(),
        'consultationFee': double.tryParse(_consultationFeeController.text.trim()) ?? 0.0,
        'languages': _selectedLanguages,
        'availability': availabilityForFirestore,
        'about': _aboutController.text.trim(),
        'status': _profileData['status'] ?? 'offline', // Preserve existing or default
        'callStatus': _profileData['callStatus'] ?? 'unavailable', // Preserve existing or default
        'rating': _profileData['rating'] ?? 0.0, // Preserve existing
        'totalReviews': _profileData['totalReviews'] ?? 0, // Preserve existing
        'patientsTreated': _profileData['patientsTreated'] ?? 0, // Preserve existing
        'createdAt': _profileData['createdAt'] ?? FieldValue.serverTimestamp(), // Preserve if exists, else new
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set(doctorDataToSave, SetOptions(merge: true));

      // Update the users collection to mark profile as complete
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isProfileSetupComplete': true,
        'profileImageUrl': uploadedProfileImageUrl, // Also update image URL in users doc for consistency
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details saved successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error saving doctor details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving details: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent immediate pop
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        await _handlePopAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your Professional Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          elevation: 2,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
            onPressed: () {
              // Manually trigger the same logic as system back press
              _handlePopAttempt();
            },
          ),
        ),
        body: _isLoadingData
            ? const Center(child: LoadingIndicator(color: AppColors.secondary, size: 50))
            : _buildFormContent(), // Your existing method
        bottomNavigationBar: _isSubmitting || _isLoadingData ? null : _buildSubmitButtonContainer(), // Your existing bottom bar
      ),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 80.0), // Padding for FAB
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImagePicker(),
            const SizedBox(height: 24),
            _buildSectionTitle("Basic Information", Icons.person_pin_rounded),
            _buildSpecialtyDropdown(),
            const SizedBox(height: 16),
            CustomTextField(controller: _qualificationsController, labelText: 'Qualifications', hintText: 'e.g., MBBS, MD, FCPS', prefixIcon: Icons.school_outlined, validator: (val) => val!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            CustomTextField(controller: _yearsOfExperienceController, labelText: 'Years of Experience', hintText: 'e.g., 5', prefixIcon: Icons.work_history_outlined, keyboardType: TextInputType.number, validator: (val) {
              if (val!.isEmpty) return 'Required';
              if (int.tryParse(val) == null || int.parse(val) < 0 || int.parse(val) > 70) return 'Invalid (0-70)';
              return null;
            }),
            const SizedBox(height: 16),
            CustomTextField(controller: _licenseNumberController, labelText: 'Medical License Number', hintText: 'Official license/registration no.', prefixIcon: Icons.verified_user_outlined, validator: (val) => val!.isEmpty ? 'Required' : (val.length < 3 ? 'Too short' : null)),
            const SizedBox(height: 16),
            CustomTextField(controller: _affiliatedInstitutionsController, labelText: 'Affiliated Institutions (Optional)', hintText: 'e.g., City Hospital', prefixIcon: Icons.business_outlined),
            const SizedBox(height: 16),
            CustomTextField(controller: _consultationFeeController, labelText: 'Consultation Fee (PKR)', hintText: 'e.g., 1500', prefixIcon: Icons.price_check_outlined, keyboardType: TextInputType.number, validator: (val) {
              if (val!.isEmpty) return 'Required';
              if (double.tryParse(val) == null || double.parse(val) < 0 || double.parse(val) > 50000) return 'Invalid (0-50000)';
              return null;
            }),

            const SizedBox(height: 24),
            _buildSectionTitle("Communication", Icons.language_rounded),
            _buildLanguagesSelection(),

            const SizedBox(height: 24),
            _buildSectionTitle("About Me", Icons.info_outline_rounded),
            CustomTextField(controller: _aboutController, labelText: 'Bio (Min 100 chars)', hintText: 'Share your experience, approach to patient care, etc.', prefixIcon: null, maxLines: 6, validator: (val) {
              if (val!.isEmpty) return 'Please write something about yourself';
              if (val.length < 100) return 'Please write at least 100 characters';
              return null;
            }),

            const SizedBox(height: 24),
            _buildSectionTitle("Availability Schedule", Icons.event_available_rounded),
            _buildAvailabilitySection(),

            const SizedBox(height: 32), // Space before potential submit button if not in bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3)),
              ],
            ),
            child: ClipOval(
              child: _profileImageFile != null
                  ? Image.file(_profileImageFile!, fit: BoxFit.cover)
                  : (_existingProfileImageUrl != null && _existingProfileImageUrl!.isNotEmpty)
                  ? Image.network(
                _existingProfileImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)),
                errorBuilder: (context, error, stack) => Icon(Icons.person, size: 80, color: AppColors.primary.withOpacity(0.6)),
              )
                  : Icon(Icons.person_add_alt_1_rounded, size: 80, color: AppColors.primary.withOpacity(0.6)),
            ),
          ),
          MaterialButton(
            onPressed: _pickImage,
            color: AppColors.secondary,
            textColor: AppColors.white,
            padding: const EdgeInsets.all(10),
            shape: const CircleBorder(),
            elevation: 2.0,
            child: const Icon(Icons.camera_alt, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecialty,
      decoration: InputDecoration(
        labelText: 'Medical Specialty *',
        prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.secondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.white,
        labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.9)),
      ),
      items: _specialtiesList.map((String specialty) {
        return DropdownMenuItem(value: specialty, child: Text(specialty));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) setState(() => _selectedSpecialty = newValue);
      },
      validator: (value) => value == null || value.isEmpty ? 'Please select your specialty' : null,
      isExpanded: true,
    );
  }

  Widget _buildLanguagesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages Spoken *', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dark.withOpacity(0.85), fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _availableLanguagesList.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language, style: TextStyle(color: isSelected ? AppColors.white : AppColors.primary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedLanguages.contains(language)) _selectedLanguages.add(language);
                  } else {
                    _selectedLanguages.remove(language);
                  }
                });
              },
              backgroundColor: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.light,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.5))
              ),
              elevation: isSelected ? 2 : 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: _daysOfWeek.map((day) {
        return _buildDayAvailabilityRow(day, _availability[day] ?? []);
      }).toList(),
    );
  }

  Widget _buildDayAvailabilityRow(String day, List<Map<String, TimeOfDay?>> slots) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
                TextButton.icon(
                  icon: const Icon(Icons.add_alarm_outlined, color: AppColors.secondary, size: 20),
                  label: const Text('Add Slot', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                  onPressed: () => _addTimeRangeDialog(day),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Not available on $day.', style: TextStyle(color: AppColors.gray, fontStyle: FontStyle.italic)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final range = slots[index];
                  final startStr = range['start']?.format(context) ?? 'N/A';
                  final endStr = range['end']?.format(context) ?? 'N/A';
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: AppColors.light.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2))
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('$startStr - $endStr', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.error.withOpacity(0.8), size: 22),
                          onPressed: () => _removeTimeRange(day, index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Remove slot",
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTimeRangeDialog(String day) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // Show Start Time Picker
    startTime = await showTimePicker(
      context: context,
      initialTime: _availability[day]!.isNotEmpty && _availability[day]!.last['end'] != null
          ? TimeOfDay(hour: (_availability[day]!.last['end']!.hour + 1) % 24, minute: 0) // Suggest start after last end time
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'SELECT START TIME FOR $day',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.light, hourMinuteTextColor: AppColors.primary,
              entryModeIconColor: AppColors.secondary, dayPeriodTextColor: AppColors.primary,
              dialHandColor: AppColors.secondary, dialTextColor: AppColors.dark,
              helpTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
          )), child: child!),
    );

    if (startTime == null || !mounted) return;

    // Show End Time Picker
    endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute),
      helpText: 'SELECT END TIME FOR $day',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.light, hourMinuteTextColor: AppColors.primary,
              entryModeIconColor: AppColors.secondary, dayPeriodTextColor: AppColors.primary,
              dialHandColor: AppColors.secondary, dialTextColor: AppColors.dark,
              helpTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
          )), child: child!),
    );

    if (endTime == null || !mounted) return;

    // Validation
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Check for overlaps
    for (var existingRange in _availability[day]!) {
      final existingStart = existingRange['start']!;
      final existingEnd = existingRange['end']!;
      final existingStartMinutes = existingStart.hour * 60 + existingStart.minute;
      final existingEndMinutes = existingEnd.hour * 60 + existingEnd.minute;

      if (startMinutes < existingEndMinutes && endMinutes > existingStartMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This time range overlaps with an existing one.'), backgroundColor: AppColors.warning),
        );
        return;
      }
    }

    setState(() {
      _availability[day]!.add({'start': startTime, 'end': endTime});
      // Sort slots by start time
      _availability[day]!.sort((a, b) {
        final aStart = a['start']!; final bStart = b['start']!;
        return (aStart.hour * 60 + aStart.minute).compareTo(bStart.hour * 60 + bStart.minute);
      });
    });
  }

  void _removeTimeRange(String day, int index) {
    if (mounted) {
      setState(() {
        _availability[day]!.removeAt(index);
      });
    }
  }

  // Method to handle the pop attempt
  Future<void> _handlePopAttempt() async {
    bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Profile Setup?'),
        content: const Text('Your changes will not be saved. Are you sure you want to exit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Don't pop
            child: const Text('Cancel', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),  // Confirm pop
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildSubmitButtonContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 0, blurRadius: 5, offset: const Offset(0, -2)),
        ],
      ),
      child: ElevatedButton.icon(
        icon: _isSubmitting ? Container() : const Icon(Icons.save_alt_outlined, color: AppColors.white),
        label: _isSubmitting
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.white)))
            : Text('Save Profile Details', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        onPressed: _isSubmitting ? null : _saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
