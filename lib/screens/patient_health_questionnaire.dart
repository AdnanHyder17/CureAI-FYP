// lib/screens/patient_health_questionnaire.dart
// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p1/screens/homeScreen.dart';
import 'package:p1/theme.dart';
import 'package:p1/widgets/custom_textfield.dart'; // Reusable text field
import 'package:p1/widgets/loading_indicator.dart'; // Reusable loading indicator
import 'package:p1/screens/login_screen.dart';

class PatientHealthQuestionnaire extends StatefulWidget {
  const PatientHealthQuestionnaire({super.key});

  @override
  _PatientHealthQuestionnaireState createState() =>
      _PatientHealthQuestionnaireState();
}

class _PatientHealthQuestionnaireState extends State<PatientHealthQuestionnaire> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // --- Form Data ---

  // Basic Info
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender; // Example: Male, Female, Other
  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say', 'Other'];


  // Health Profile
  bool _hasChronicConditions = false;
  final Map<String, bool> _chronicConditionsSelected = {
    'Diabetes': false, 'Hypertension (High Blood Pressure)': false, 'Asthma': false,
    'Heart Disease': false, 'Kidney Disease': false, 'Thyroid Disorder': false,
  };
  final TextEditingController _chronicConditionsOtherController = TextEditingController();

  bool _hasFamilyHistory = false;
  final Map<String, bool> _familyHealthHistorySelected = {
    'Diabetes': false, 'Heart Disease': false, 'Hypertension': false,
    'Stroke': false, 'Cancer': false, 'Mental Health Conditions': false,
  };
  final TextEditingController _familyHealthHistoryOtherController = TextEditingController();

  bool _hasAllergies = false;
  final TextEditingController _allergiesDetailsController = TextEditingController(); // Single field for all allergies

  bool _hasSurgicalHistory = false;
  final TextEditingController _surgicalHistoryDetailsController = TextEditingController();

  bool _takingCurrentMedications = false;
  final TextEditingController _currentMedicationsDetailsController = TextEditingController(); // Includes OTC & supplements

  // Lifestyle Habits
  String? _selectedSmokingStatus; // Non-smoker, Former smoker, Current smoker
  final List<String> _smokingStatusOptions = ['Non-smoker', 'Former smoker', 'Current smoker (Daily)', 'Current smoker (Occasionally)'];
  final TextEditingController _smokingDetailsController = TextEditingController(); // If current/former, details

  String? _selectedAlcoholConsumption; // Never, Rarely, Moderately, Frequently
  final List<String> _alcoholConsumptionOptions = ['Never', 'Rarely (Socially/Monthly)', 'Moderately (Weekly)', 'Frequently (Daily/Almost Daily)'];
  final TextEditingController _alcoholDetailsController = TextEditingController();

  String? _selectedDietaryHabits; // Balanced, Vegetarian, Vegan, Low-carb, etc.
  final List<String> _dietaryHabitOptions = [
    'Generally balanced', 'High in processed foods', 'Vegetarian', 'Vegan',
    'Low-carb (Keto, Atkins)', 'Low-fat', 'Gluten-free', 'Other specific diet'
  ];
  final TextEditingController _dietaryHabitsOtherController = TextEditingController();

  String? _selectedPhysicalActivityLevel; // Sedentary, Light, Moderate, Vigorous
  final List<String> _physicalActivityOptions = [
    'Sedentary (Little to no exercise)',
    'Lightly active (Light exercise/sports 1-3 days/week)',
    'Moderately active (Moderate exercise/sports 3-5 days/week)',
    'Very active (Hard exercise/sports 6-7 days a week)',
    'Extremely active (Very hard exercise/physical job)'
  ];

  String? _selectedSleepDuration; // e.g. <6 hours, 7-8 hours, >9 hours
  final List<String> _sleepDurationOptions = ['Less than 5 hours', '5-6 hours', '7-8 hours', 'More than 8 hours'];
  String? _selectedSleepQuality; // Good, Fair, Poor
  final List<String> _sleepQualityOptions = ['Good (Wake up refreshed)', 'Fair (Somewhat restful)', 'Poor (Wake up tired)'];


  String? _selectedStressLevel; // Low, Moderate, High
  final List<String> _stressLevelOptions = ['Low (Rarely stressed)', 'Moderate (Manageable stress)', 'High (Frequently stressed)', 'Very High (Constantly stressed)'];
  final TextEditingController _stressCopingMechanismsController = TextEditingController();

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _ageController.dispose();
    _chronicConditionsOtherController.dispose();
    _familyHealthHistoryOtherController.dispose();
    _allergiesDetailsController.dispose();
    _surgicalHistoryDetailsController.dispose();
    _currentMedicationsDetailsController.dispose();
    _smokingDetailsController.dispose();
    _alcoholDetailsController.dispose();
    _dietaryHabitsOtherController.dispose();
    _stressCopingMechanismsController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      // Find the first step with an error and navigate to it
      for (int i = 0; i < getSteps(context).length; i++) {
        // This is a bit tricky as validation happens on the overall form.
        // A more robust solution would be per-step validation or focusing on the first invalid field.
        // For now, just show a general message.
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please review your answers. Some required fields are missing or invalid.'), backgroundColor: AppColors.error),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Cannot save data.'), backgroundColor: AppColors.error),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    Map<String, dynamic> patientData = {
      'uid': _currentUser!.uid,
      'email': _currentUser!.email, // Denormalize for easier access if needed
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdAt': _profileData['createdAt'] ?? FieldValue.serverTimestamp(), // Preserve if editing

      'basicInfo': {
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _selectedGender,
      },
      'healthProfile': {
        'hasChronicConditions': _hasChronicConditions,
        'chronicConditionsSelected': _hasChronicConditions ? _chronicConditionsSelected.entries.where((e)=>e.value).map((e)=>e.key).toList() : [],
        'chronicConditionsOther': (_hasChronicConditions && _chronicConditionsOtherController.text.trim().isNotEmpty) ? _chronicConditionsOtherController.text.trim() : '',

        'hasFamilyHistory': _hasFamilyHistory,
        'familyHealthHistorySelected': _hasFamilyHistory ? _familyHealthHistorySelected.entries.where((e)=>e.value).map((e)=>e.key).toList() : [],
        'familyHealthHistoryOther': (_hasFamilyHistory && _familyHealthHistoryOtherController.text.trim().isNotEmpty) ? _familyHealthHistoryOtherController.text.trim() : '',

        'hasAllergies': _hasAllergies,
        'allergiesDetails': _hasAllergies ? _allergiesDetailsController.text.trim() : '',

        'hasSurgicalHistory': _hasSurgicalHistory,
        'surgicalHistoryDetails': _hasSurgicalHistory ? _surgicalHistoryDetailsController.text.trim() : '',

        'takingCurrentMedications': _takingCurrentMedications,
        'currentMedicationsDetails': _takingCurrentMedications ? _currentMedicationsDetailsController.text.trim() : '',
      },
      'lifestyleHabits': {
        'smokingStatus': _selectedSmokingStatus,
        'smokingDetails': (_selectedSmokingStatus == 'Former smoker' || _selectedSmokingStatus?.startsWith('Current smoker') == true) ? _smokingDetailsController.text.trim() : '',
        'alcoholConsumption': _selectedAlcoholConsumption,
        'alcoholDetails': (_selectedAlcoholConsumption == 'Moderately (Weekly)' || _selectedAlcoholConsumption == 'Frequently (Daily/Almost Daily)') ? _alcoholDetailsController.text.trim() : '',
        'dietaryHabits': _selectedDietaryHabits,
        'dietaryHabitsOther': (_selectedDietaryHabits == 'Other specific diet') ? _dietaryHabitsOtherController.text.trim() : '',
        'physicalActivityLevel': _selectedPhysicalActivityLevel,
        'sleepDuration': _selectedSleepDuration,
        'sleepQuality': _selectedSleepQuality,
        'stressLevel': _selectedStressLevel,
        'stressCopingMechanisms': _stressCopingMechanismsController.text.trim(),
      },
    };
    // Add existing profile data if any (especially profileImageUrl from 'users' or 'patients' collection)
    if (_profileData.containsKey('profileImageUrl')) {
      patientData['profileImageUrl'] = _profileData['profileImageUrl'];
    }


    try {
      await _firestore.collection('patients').doc(_currentUser!.uid).set(patientData, SetOptions(merge: true));

      // Update the users collection to mark profile as complete
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'isProfileSetupComplete': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health information saved successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Error saving patient data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  // To store loaded profile data if user is editing
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadPatientDataForEditing(); // Load data if user is editing
  }

  Future<void> _loadPatientDataForEditing() async {
    if (_currentUser == null) return;
    setState(() => _isSubmitting = true); // Use _isSubmitting as a general loading flag here

    try {
      DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(_currentUser!.uid).get();
      if (mounted && patientDoc.exists) {
        _profileData = patientDoc.data() as Map<String, dynamic>;

        // Basic Info
        _ageController.text = (_profileData['basicInfo']?['age'] ?? '').toString();
        _selectedGender = _profileData['basicInfo']?['gender'];

        // Health Profile
        final healthProfile = _profileData['healthProfile'] as Map<String, dynamic>? ?? {};
        _hasChronicConditions = healthProfile['hasChronicConditions'] ?? false;
        _chronicConditionsOtherController.text = healthProfile['chronicConditionsOther'] ?? '';
        (healthProfile['chronicConditionsSelected'] as List<dynamic>? ?? []).forEach((item) {
          if (_chronicConditionsSelected.containsKey(item)) _chronicConditionsSelected[item] = true;
        });

        _hasFamilyHistory = healthProfile['hasFamilyHistory'] ?? false;
        _familyHealthHistoryOtherController.text = healthProfile['familyHealthHistoryOther'] ?? '';
        (healthProfile['familyHealthHistorySelected'] as List<dynamic>? ?? []).forEach((item) {
          if (_familyHealthHistorySelected.containsKey(item)) _familyHealthHistorySelected[item] = true;
        });

        _hasAllergies = healthProfile['hasAllergies'] ?? false;
        _allergiesDetailsController.text = healthProfile['allergiesDetails'] ?? '';
        _hasSurgicalHistory = healthProfile['hasSurgicalHistory'] ?? false;
        _surgicalHistoryDetailsController.text = healthProfile['surgicalHistoryDetails'] ?? '';
        _takingCurrentMedications = healthProfile['takingCurrentMedications'] ?? false;
        _currentMedicationsDetailsController.text = healthProfile['currentMedicationsDetails'] ?? '';

        // Lifestyle Habits
        final lifestyle = _profileData['lifestyleHabits'] as Map<String, dynamic>? ?? {};
        _selectedSmokingStatus = lifestyle['smokingStatus'];
        _smokingDetailsController.text = lifestyle['smokingDetails'] ?? '';
        _selectedAlcoholConsumption = lifestyle['alcoholConsumption'];
        _alcoholDetailsController.text = lifestyle['alcoholDetails'] ?? '';
        _selectedDietaryHabits = lifestyle['dietaryHabits'];
        _dietaryHabitsOtherController.text = lifestyle['dietaryHabitsOther'] ?? '';
        _selectedPhysicalActivityLevel = lifestyle['physicalActivityLevel'];
        _selectedSleepDuration = lifestyle['sleepDuration'];
        _selectedSleepQuality = lifestyle['sleepQuality'];
        _selectedStressLevel = lifestyle['stressLevel'];
        _stressCopingMechanismsController.text = lifestyle['stressCopingMechanisms'] ?? '';

      }
    } catch (e) {
      debugPrint("Error loading existing patient data: $e");
      // Handle error appropriately, maybe show a snackbar
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  void _nextStep() {
    // Optional: Add per-step validation here if desired
    if (_currentStep < getSteps(context).length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _saveData();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  // --- UI Helper Widgets ---
  Widget _buildYesNoToggle({
    required String question,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                text: 'YES',
                isSelected: currentValue,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleButton(
                text: 'NO',
                isSelected: !currentValue,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckboxGroup({
    required String title,
    required Map<String, bool> options,
    required Function(String, bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.keys.map((key) {
            return FilterChip(
              label: Text(key, style: TextStyle(color: options[key]! ? AppColors.white : AppColors.primary)),
              selected: options[key]!,
              onSelected: (selected) => onChanged(key, selected),
              backgroundColor: AppColors.light,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: options[key]! ? AppColors.primary : AppColors.gray.withOpacity(0.7)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdownFormField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Select an option',
          prefixIcon: Icon(icon, color: AppColors.secondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: AppColors.white,
          labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.9)),
        ),
        isExpanded: true,
        style: const TextStyle(color: AppColors.dark, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
      ),
    );
  }

  // --- Step Content Builders ---
  List<Step> getSteps(BuildContext context) => [
    _buildStep(title: 'Basic Information', content: _buildBasicInfoStep(context), stepIndex: 0),
    _buildStep(title: 'Medical Conditions', content: _buildMedicalConditionsStep(context), stepIndex: 1),
    _buildStep(title: 'Family & Allergies', content: _buildFamilyAllergiesStep(context), stepIndex: 2),
    _buildStep(title: 'Medical History', content: _buildMedicalHistoryStep(context), stepIndex: 3),
    _buildStep(title: 'Lifestyle Habits', content: _buildLifestyleHabitsStep(context), stepIndex: 4),
    _buildStep(title: 'Activity & Sleep', content: _buildActivitySleepStep(context), stepIndex: 5),
    _buildStep(title: 'Well-being', content: _buildWellBeingStep(context), stepIndex: 6),
  ];

  Step _buildStep({required String title, required Widget content, required int stepIndex}) {
    return Step(
      title: Text(title, style: TextStyle(fontWeight: _currentStep == stepIndex ? FontWeight.bold : FontWeight.normal, color: _currentStep == stepIndex ? AppColors.primary : AppColors.dark)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: content,
      ),
      isActive: _currentStep >= stepIndex,
      state: _currentStep > stepIndex ? StepState.complete : (_currentStep == stepIndex ? StepState.editing : StepState.indexed),
    );
  }

  Widget _buildBasicInfoStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Let's start with some basics", icon: Icons.person_outline_rounded),
        CustomTextField(controller: _ageController, labelText: "Your Age *", prefixIcon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0 || int.parse(val) > 120) ? 'Valid age required' : null),
        const SizedBox(height: 16),
        _buildDropdownFormField<String>(
          label: 'Gender *',
          icon: Icons.wc_rounded,
          value: _selectedGender,
          items: _genderOptions,
          onChanged: (val) => setState(() => _selectedGender = val),
          validator: (val) => val == null ? 'Please select your gender' : null,
        ),
      ],
    );
  }

  Widget _buildMedicalConditionsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Chronic Health Conditions", icon: Icons.monitor_heart_outlined),
        _buildYesNoToggle(question: "Do you have any ongoing or significant past chronic health conditions? *", currentValue: _hasChronicConditions, onChanged: (val) => setState(() => _hasChronicConditions = val)),
        if (_hasChronicConditions) ...[
          const SizedBox(height: 16),
          _buildCheckboxGroup(title: "Please select any conditions you have/had:", options: _chronicConditionsSelected, onChanged: (key, selected) => setState(() => _chronicConditionsSelected[key] = selected)),
          const SizedBox(height: 16),
          CustomTextField(controller: _chronicConditionsOtherController, labelText: "Other conditions or details", prefixIcon: Icons.playlist_add_outlined, maxLines: 3, validator: (val) => (_hasChronicConditions && _chronicConditionsSelected.entries.where((e) => e.value).isEmpty && (val == null || val.isEmpty)) ? 'Please specify or select a condition' : null),
        ],
      ],
    );
  }

  Widget _buildFamilyAllergiesStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Family Health History", icon: Icons.family_restroom_rounded),
        _buildYesNoToggle(question: "Any significant health conditions in your immediate family (parents, siblings)? *", currentValue: _hasFamilyHistory, onChanged: (val) => setState(() => _hasFamilyHistory = val)),
        if (_hasFamilyHistory) ...[
          const SizedBox(height: 16),
          _buildCheckboxGroup(title: "Select any relevant family conditions:", options: _familyHealthHistorySelected, onChanged: (key, selected) => setState(() => _familyHealthHistorySelected[key] = selected)),
          const SizedBox(height: 16),
          CustomTextField(controller: _familyHealthHistoryOtherController, labelText: "Other family conditions or details", prefixIcon: Icons.playlist_add_outlined, maxLines: 3),
        ],
        const SizedBox(height: 24),
        _SectionHeader(title: "Allergies", icon: Icons.sick),
        _buildYesNoToggle(question: "Do you have any known allergies (medications, food, environmental)? *", currentValue: _hasAllergies, onChanged: (val) => setState(() => _hasAllergies = val)),
        if (_hasAllergies) ...[
          const SizedBox(height: 16),
          CustomTextField(controller: _allergiesDetailsController, labelText: "Please list your allergies and reactions *", prefixIcon: Icons.warning_amber_rounded, maxLines: 3, validator: (val) => (_hasAllergies && (val == null || val.isEmpty)) ? 'Please specify your allergies' : null),
        ],
      ],
    );
  }

  Widget _buildMedicalHistoryStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Surgeries & Medications", icon: Icons.medical_information_outlined),
        _buildYesNoToggle(question: "Have you had any surgeries in the past? *", currentValue: _hasSurgicalHistory, onChanged: (val) => setState(() => _hasSurgicalHistory = val)),
        if (_hasSurgicalHistory) ...[
          const SizedBox(height: 16),
          CustomTextField(controller: _surgicalHistoryDetailsController, labelText: "Please list surgeries and approximate year(s) *", prefixIcon: Icons.healing_outlined, maxLines: 3, validator: (val) => (_hasSurgicalHistory && (val == null || val.isEmpty)) ? 'Please provide surgery details' : null),
        ],
        const SizedBox(height: 24),
        _buildYesNoToggle(question: "Are you currently taking any medications (prescription, OTC, supplements)? *", currentValue: _takingCurrentMedications, onChanged: (val) => setState(() => _takingCurrentMedications = val)),
        if (_takingCurrentMedications) ...[
          const SizedBox(height: 16),
          CustomTextField(controller: _currentMedicationsDetailsController, labelText: "List current medications, dosage, and frequency *", prefixIcon: Icons.medication_liquid_outlined, maxLines: 4, validator: (val) => (_takingCurrentMedications && (val == null || val.isEmpty)) ? 'Please list your medications' : null),
        ],
      ],
    );
  }

  Widget _buildLifestyleHabitsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Smoking & Alcohol", icon: Icons.smoking_rooms_rounded),
        _buildDropdownFormField<String>(label: 'Smoking Status *', icon: Icons.smoking_rooms, value: _selectedSmokingStatus, items: _smokingStatusOptions, onChanged: (val) => setState(() => _selectedSmokingStatus = val), validator: (val) => val == null ? 'Required' : null),
        if (_selectedSmokingStatus == 'Former smoker' || _selectedSmokingStatus?.startsWith('Current smoker') == true)
          CustomTextField(controller: _smokingDetailsController, labelText: "Details (e.g., how much/long, quit date)", prefixIcon: Icons.edit_note_outlined, maxLines: 2),

        const SizedBox(height: 16),
        _buildDropdownFormField<String>(label: 'Alcohol Consumption *', icon: Icons.no_drinks_rounded, value: _selectedAlcoholConsumption, items: _alcoholConsumptionOptions, onChanged: (val) => setState(() => _selectedAlcoholConsumption = val), validator: (val) => val == null ? 'Required' : null),
        if (_selectedAlcoholConsumption == 'Moderately (Weekly)' || _selectedAlcoholConsumption == 'Frequently (Daily/Almost Daily)')
          CustomTextField(controller: _alcoholDetailsController, labelText: "Details (e.g., type, quantity per week)", prefixIcon: Icons.edit_note_outlined, maxLines: 2),


        const SizedBox(height: 24),
        _SectionHeader(title: "Dietary Habits", icon: Icons.restaurant_menu_rounded),
        _buildDropdownFormField<String>(label: 'Primary Dietary Pattern *', icon: Icons.fastfood_outlined, value: _selectedDietaryHabits, items: _dietaryHabitOptions, onChanged: (val) => setState(() => _selectedDietaryHabits = val), validator: (val) => val == null ? 'Required' : null),
        if (_selectedDietaryHabits == 'Other specific diet')
          CustomTextField(controller: _dietaryHabitsOtherController, labelText: "Specify your diet *", prefixIcon: Icons.edit_note_outlined, validator: (val) => (_selectedDietaryHabits == 'Other specific diet' && (val == null || val.isEmpty)) ? 'Please specify' : null),
      ],
    );
  }

  Widget _buildActivitySleepStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Physical Activity", icon: Icons.fitness_center_rounded),
        _buildDropdownFormField<String>(label: 'Typical Physical Activity Level *', icon: Icons.directions_run_rounded, value: _selectedPhysicalActivityLevel, items: _physicalActivityOptions, onChanged: (val) => setState(() => _selectedPhysicalActivityLevel = val), validator: (val) => val == null ? 'Required' : null),

        const SizedBox(height: 24),
        _SectionHeader(title: "Sleep Patterns", icon: Icons.bedtime_rounded),
        _buildDropdownFormField<String>(label: 'Average Sleep Duration per Night *', icon: Icons.timer_outlined, value: _selectedSleepDuration, items: _sleepDurationOptions, onChanged: (val) => setState(() => _selectedSleepDuration = val), validator: (val) => val == null ? 'Required' : null),
        const SizedBox(height: 16),
        _buildDropdownFormField<String>(label: 'General Sleep Quality *', icon: Icons.star_outline_rounded, value: _selectedSleepQuality, items: _sleepQualityOptions, onChanged: (val) => setState(() => _selectedSleepQuality = val), validator: (val) => val == null ? 'Required' : null),
      ],
    );
  }

  Widget _buildWellBeingStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Stress & Well-being", icon: Icons.spa_outlined),
        _buildDropdownFormField<String>(label: 'General Stress Level *', icon: Icons.sentiment_very_dissatisfied_rounded, value: _selectedStressLevel, items: _stressLevelOptions, onChanged: (val) => setState(() => _selectedStressLevel = val), validator: (val) => val == null ? 'Required' : null),
        const SizedBox(height: 16),
        CustomTextField(controller: _stressCopingMechanismsController, labelText: "How do you usually cope with stress?", prefixIcon: Icons.psychology_outlined, maxLines: 3),
      ],
    );
  }

  Future<void> _handlePopAttempt() async {
    bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Questionnaire?'),
        content: const Text('Your progress will not be saved. Are you sure you want to exit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User chose not to pop
            child: const Text('Cancel', style: TextStyle(color: AppColors.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),  // User confirmed to pop
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldPop == true && mounted) {
      // Navigate to LoginScreen or another appropriate screen, clearing the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent immediate pop, handle it in onPopInvokedWithResult
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // This is called after an attempt to pop the screen.
        // The 'result' parameter contains the value the route would have returned if popped.
        // If didPop is true, it means the pop happened (e.g. if canPop was true, or Navigator.pop was called).
        // If didPop is false, it means canPop was false, and the pop was blocked by the PopScope.
        if (didPop) {
          return; // Pop already happened (e.g. if we called Navigator.pop elsewhere), nothing more to do.
        }
        // If pop was blocked (canPop: false), then show our confirmation dialog.
        await _handlePopAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your Health Profile',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
            onPressed: () {
              // Manually trigger the same logic as system back press
              _handlePopAttempt();
            },
          ),
        ),
        body: _isSubmitting
            ? const Center(
          child: LoadingIndicator(
            color: AppColors.secondary,
            size: 50,
          ),
        )
            : Form(
          key: _formKey,
          child: Stepper(
            physics: const ClampingScrollPhysics(),
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _prevStep,
            steps: getSteps(context),
            controlsBuilder: (context, ControlsDetails controls) {
              final isLastStep = _currentStep == getSteps(context).length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Row(
                  children: <Widget>[
                    if (_currentStep > 0)
                      OutlinedButton.icon(
                        onPressed: controls.onStepCancel,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        label: const Text('BACK'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: controls.onStepContinue,
                      icon: Icon(
                        isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded,
                        size: 20,
                      ),
                      label: Text(isLastStep ? 'SUBMIT PROFILE' : 'NEXT STEP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}

// Reusable Section Header for Stepper content
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Toggle Button for Yes/No
class _ToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.light,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.gray.withOpacity(0.7)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
