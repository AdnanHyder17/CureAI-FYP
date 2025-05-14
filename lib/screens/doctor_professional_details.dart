// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:p1/theme.dart';
import 'package:p1/screens/doctor_dashboard_screen.dart';

class DoctorProfessionalDetails extends StatefulWidget {
  const DoctorProfessionalDetails({super.key});

  @override
  _DoctorProfessionalDetailsState createState() =>
      _DoctorProfessionalDetailsState();
}

class _DoctorProfessionalDetailsState extends State<DoctorProfessionalDetails> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  File? _profileImage;
  String _selectedSpecialty = ''; // For Dropdown
  final List<String> _selectedLanguages = []; // For FilterChips

  // TextEditingControllers for TextFormFields
  final TextEditingController _qualificationsController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _affiliatedInstitutionsController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  // Availability: UI uses TimeOfDay, Firestore uses String "HH:mm"
  final Map<String, List<Map<String, TimeOfDay?>>> _availability = {
    'Monday': [], 'Tuesday': [], 'Wednesday': [],
    'Thursday': [], 'Friday': [], 'Saturday': [], 'Sunday': []
  };

  bool _isSubmitting = false;
  bool _isLoadingData = true;
  Map<String, dynamic> _profileData = {}; // To store existing profile data

  final List<String> _specialtiesList = [
    'Cardiology', 'Dermatology', 'Endocrinology', 'Family Medicine',
    'Gastroenterology', 'Neurology', 'Obstetrics', 'Pediatrics',
    'Psychiatry', 'Orthopedics', 'Ophthalmology', 'Gynecology', 'Other'
  ];

  final List<String> _availableLanguagesList = [
    'English', 'Spanish', 'French', 'German', 'Chinese', 'Arabic', 'Hindi', 'Urdu', 'Portuguese', 'Russian'
  ];

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
    setState(() {
      _isLoadingData = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoadingData = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return;
    }

    try {
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (mounted && doctorDoc.exists) {
        _profileData = doctorDoc.data() as Map<String, dynamic>;

        _selectedSpecialty = _profileData['specialty'] ?? '';
        _qualificationsController.text = _profileData['qualifications'] ?? '';
        _yearsOfExperienceController.text = (_profileData['yearsOfExperience'] ?? 0).toString();
        _licenseNumberController.text = _profileData['licenseNumber'] ?? '';
        _affiliatedInstitutionsController.text = _profileData['affiliatedInstitutions'] ?? '';
        _consultationFeeController.text = (_profileData['consultationFee'] ?? 0.0).toStringAsFixed(0); // Assuming fee is integer like
        _aboutController.text = _profileData['about'] ?? '';

        if (_profileData['languages'] is List) {
          _selectedLanguages.clear();
          _selectedLanguages.addAll(List<String>.from(_profileData['languages']));
        }

        // Parse availability
        _availability.updateAll((key, value) => []); // Clear existing UI state

        if (_profileData['availability'] != null && _profileData['availability'] is Map) {
          final Map<String, dynamic> availabilityFromDb = Map<String, dynamic>.from(_profileData['availability']);

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
                    if (parts.length == 2) {
                      startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                    }
                  }
                  if (endStr != null && endStr.isNotEmpty) {
                    final parts = endStr.split(':');
                    if (parts.length == 2) {
                      endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                    }
                  }
                  if (startTime != null && endTime != null) {
                    daySlots.add({'start': startTime, 'end': endTime});
                  }
                }
              }
              _availability[dayKey] = daySlots;
            }
          });
        }
      } else {
        _availability.updateAll((key, value) => []); // Ensure empty lists if no profile
      }
    } catch (e) {
      debugPrint("Error loading doctor data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: ${e.toString()}')),
      );
      _availability.updateAll((key, value) => []);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      if (mounted) {
        setState(() => _profileImage = File(image.path));
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_profileImage == null) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('doctor_profiles')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    try {
      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language you speak.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    // Optional: Add validation for at least one availability slot if desired

    if (mounted) setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDocSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String doctorNickname = userDocSnapshot.exists && userDocSnapshot.data()!.containsKey('nickname')
          ? userDocSnapshot.data()!['nickname'] as String
          : 'Dr. Unknown';

      final String? uploadedProfileImageUrl = await _uploadImage();

      Map<String, List<Map<String, String>>> availabilityStr = {};
      _availability.forEach((day, ranges) {
        availabilityStr[day] = ranges
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
        'nickname': doctorNickname,
        'nickname_lowercase': doctorNickname.toLowerCase(),
        'specialty': _selectedSpecialty,
        'specialty_lowercase': _selectedSpecialty.toLowerCase(),
        'qualifications': _qualificationsController.text,
        'yearsOfExperience': int.tryParse(_yearsOfExperienceController.text) ?? 0,
        'licenseNumber': _licenseNumberController.text,
        'affiliatedInstitutions': _affiliatedInstitutionsController.text,
        'consultationFee': double.tryParse(_consultationFeeController.text) ?? 0.0,
        'languages': _selectedLanguages,
        'availability': availabilityStr,
        'about': _aboutController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'rating': _profileData['rating'] ?? 0.0,
        'totalReviews': _profileData['totalReviews'] ?? 0,
        'status': _profileData['status'] ?? 'active',
        'callStatus': _profileData['callStatus'] ?? 'available',
        'patientsTreated': _profileData['patientsTreated'] ?? 0,
      };

      if (uploadedProfileImageUrl != null) {
        doctorDataToSave['profileImageUrl'] = uploadedProfileImageUrl;
      } else if (_profileData.containsKey('profileImageUrl') && _profileData['profileImageUrl'] != null) {
        doctorDataToSave['profileImageUrl'] = _profileData['profileImageUrl'];
      } else {
        doctorDataToSave['profileImageUrl'] = null;
      }

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set(doctorDataToSave, SetOptions(merge: true));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingData
          ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary)),
              const SizedBox(height: 20),
              Text('Loading profile...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ))
          : _isSubmitting
          ? _buildLoadingIndicator()
          : _buildForm(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary)),
          SizedBox(height: 20),
          Text('Submitting your details...',),
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
            _buildSectionTitle("Basic Information"),
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
            const SizedBox(height: 24),
            _buildSectionTitle("Communication"),
            _buildLanguagesSelection(),
            const SizedBox(height: 24),
            _buildSectionTitle("About Me"),
            _buildAboutInput(),
            const SizedBox(height: 24),
            _buildSectionTitle("Availability Schedule"),
            _buildAvailabilitySection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    String? existingImageUrl = _profileData['profileImageUrl'] as String?;
    return Center(
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                  : (existingImageUrl != null && existingImageUrl.isNotEmpty)
                  ? Image.network(existingImageUrl, fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorBuilder: (context, error, stack) => Icon(Icons.person, size: 70, color: AppColors.primary.withOpacity(0.5)),
              )
                  : Icon(Icons.person_add_alt_1, size: 70, color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20, color: AppColors.white),
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
      value: _selectedSpecialty.isNotEmpty && _specialtiesList.contains(_selectedSpecialty) ? _selectedSpecialty : null,
      decoration: _getInputDecoration('Medical Specialty', 'Select your specialty', Icons.medical_services_outlined),
      items: _specialtiesList.map((String specialty) {
        return DropdownMenuItem(value: specialty, child: Text(specialty));
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) setState(() => _selectedSpecialty = newValue);
      },
      validator: (value) => value == null || value.isEmpty ? 'Please select your specialty' : null,
      onSaved: (value) => _selectedSpecialty = value ?? '',
    );
  }

  Widget _buildQualificationsInput() {
    return TextFormField(
      controller: _qualificationsController,
      decoration: _getInputDecoration('Qualifications', 'e.g., MBBS, MD, FCPS', Icons.school_outlined),
      validator: (value) => value == null || value.isEmpty ? 'Please enter your qualifications' : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildExperienceInput() {
    return TextFormField(
      controller: _yearsOfExperienceController,
      decoration: _getInputDecoration('Years of Experience', 'Enter total years of practice', Icons.work_history_outlined),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter years of experience';
        final years = int.tryParse(value);
        if (years == null) return 'Please enter a valid number.';
        if (years < 0 || years > 70) return 'Please enter a valid number of years (0-70)';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildLicenseInput() {
    return TextFormField(
      controller: _licenseNumberController,
      decoration: _getInputDecoration('Medical License Number', 'Enter official license/registration no.', Icons.verified_user_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your license number';
        if (value.length < 3) return 'License number seems too short';
        return null;
      },
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildInstitutionsInput() {
    return TextFormField(
      controller: _affiliatedInstitutionsController,
      decoration: _getInputDecoration('Affiliated Institutions (Optional)', 'e.g., City Hospital, Medical Center', Icons.business_outlined),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConsultationFeeInput() {
    return TextFormField(
      controller: _consultationFeeController,
      decoration: _getInputDecoration('Consultation Fee (PKR)', 'Enter fee per session', Icons.price_check_outlined).copyWith(prefixText: 'Rs. '),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter consultation fee';
        final fee = double.tryParse(value);
        if (fee == null) return 'Please enter a valid amount';
        if (fee < 0) return 'Fee cannot be negative';
        if (fee > 50000) return 'Fee seems too high (max Rs 50000)';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildLanguagesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages Spoken', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dark.withOpacity(0.8))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _availableLanguagesList.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.dark)),
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
              backgroundColor: AppColors.light,
              selectedColor: AppColors.secondary.withOpacity(0.3),
              checkmarkColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.5))
              ),
            );
          }).toList(),
        ),
        if (_formKey.currentState?.validate() == true && _selectedLanguages.isEmpty && _isSubmitting) // Show validation error for languages only after first submit attempt
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Please select at least one language.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildAboutInput() {
    return TextFormField(
      controller: _aboutController,
      decoration: _getInputDecoration('About Yourself (Min 100 chars)', 'Share your experience, approach to patient care, etc.', Icons.info_outline)
          .copyWith(alignLabelWithHint: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
      maxLines: 6,
      maxLength: 600,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please write something about yourself';
        if (value.length < 100) return 'Please write at least 100 characters';
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      children: _availability.entries.map((entry) {
        return _buildDayAvailabilityRow(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildDayAvailabilityRow(String day, List<Map<String, TimeOfDay?>> slots) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.dark)),
                TextButton.icon(
                  icon: Icon(Icons.add_alarm_outlined, color: AppColors.primary, size: 18),
                  label: const Text('Add Time Range', style: TextStyle(color: AppColors.primary)),
                  onPressed: () => _addTimeRange(day),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Not available on $day', style: TextStyle(color: AppColors.gray.withOpacity(0.8), fontStyle: FontStyle.italic)),
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
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                        color: AppColors.light.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.access_time, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('$startStr - $endStr', style: const TextStyle(fontWeight: FontWeight.w500))),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: AppColors.error.withOpacity(0.8), size: 22),
                          onPressed: () => _removeTimeRange(day, index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

  Future<void> _addTimeRange(String day) async {
    TimeOfDay initialStartTime = const TimeOfDay(hour: 9, minute: 0);
    // If there are existing slots for the day, suggest start time after the last end time
    if (_availability[day]!.isNotEmpty) {
      final lastSlot = _availability[day]!.last;
      if (lastSlot['end'] != null) {
        initialStartTime = TimeOfDay(hour: (lastSlot['end']!.hour + 1) % 24, minute: 0);
      }
    }


    TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: initialStartTime,
        helpText: 'SELECT START TIME FOR $day',
        builder: (context, child) {
          return Theme(data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                  backgroundColor: AppColors.light,
                  hourMinuteTextColor: AppColors.primary,
                  entryModeIconColor: AppColors.secondary,
                  dayPeriodTextColor: AppColors.primary,
                  dialHandColor: AppColors.secondary,
                  dialTextColor: AppColors.dark,
                  helpTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
              )
          ), child: child!);
        }
    );
    if (startTime == null || !mounted) return;

    TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute),
        helpText: 'SELECT END TIME FOR $day',
        builder: (context, child) { // Consistent theming
          return Theme(data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                  backgroundColor: AppColors.light,
                  hourMinuteTextColor: AppColors.primary,
                  entryModeIconColor: AppColors.secondary,
                  dayPeriodTextColor: AppColors.primary,
                  dialHandColor: AppColors.secondary,
                  dialTextColor: AppColors.dark,
                  helpTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
              )
          ), child: child!);
        }
    );
    if (endTime == null || !mounted) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Check for overlaps with existing ranges for the same day
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
      _availability[day]!.sort((a, b) {
        final aStart = a['start']!;
        final bStart = b['start']!;
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSubmitting ? Container() : const Icon(Icons.save_alt_outlined, color: AppColors.white),
        label: _isSubmitting
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.white)))
            : Text('Save Profile Details', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.white, fontSize: 16)),
        onPressed: _isSubmitting ? null : _saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label.isNotEmpty ? label : null,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
      labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.9)),
      hintStyle: TextStyle(color: AppColors.gray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.gray.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.gray.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.white, // Or AppColors.light.withOpacity(0.5)
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}