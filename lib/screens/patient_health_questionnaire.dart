// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p1/screens/homeScreen.dart'; // Assuming this is the patient's home screen
import 'package:p1/theme.dart';

class PatientHealthQuestionnaire extends StatefulWidget {
  const PatientHealthQuestionnaire({super.key});

  @override
  _PatientHealthQuestionnaireState createState() =>
      _PatientHealthQuestionnaireState();
}

class _PatientHealthQuestionnaireState
    extends State<PatientHealthQuestionnaire> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // --- State Variables for Questionnaire Data ---

  // Basic
  final TextEditingController _ageController = TextEditingController();

  // Health Profile
  bool _hasChronicConditions = false; // NEW: Main Yes/No for chronic conditions
  final Map<String, bool> _chronicConditionsSelected = {
    'Diabetes': false,
    'Hypertension': false,
    'Cardiovascular Disease': false,
    'Thyroid Disorders': false,
  };
  final TextEditingController _chronicConditionsOtherController = TextEditingController();
  bool _hasOtherChronicConditions = false;

  bool _hasFamilyHistory = false; // NEW: Main Yes/No for family history
  final Map<String, bool> _familyHealthHistorySelected = {
    'Heart Diseases': false,
    'Diabetes': false,
    'Cancer': false,
    'Osteoporosis': false,
  };
  final TextEditingController _familyHealthHistoryOtherController = TextEditingController();
  bool _hasOtherFamilyHistory = false;

  bool _hasAllergies = false; // Existing: Main Yes/No for allergies
  final Map<String, bool> _knownAllergiesSelected = {
    'Soy': false,
    'Dairy/Lactose': false,
    'Fish/Shellfish': false,
  };
  final TextEditingController _knownAllergiesOtherController = TextEditingController();
  bool _hasOtherAllergies = false; // Existing: For the "Other Allergies"

  bool _hasSurgicalHistory = false;
  final TextEditingController _surgicalHistoryDetailsController = TextEditingController();

  bool _takingCurrentMedications = false;
  final TextEditingController _currentMedicationsController = TextEditingController();

  bool _hasMedicationHistory = false;
  final TextEditingController _medicationHistoryController = TextEditingController();

  // Life Patterns & Habits
  String? _selectedSmokingIntensity;
  final List<String> _smokingOptions = [
    'Non-smoker', '1-10 cigarettes', 'About 1 pack', 'More than 1 pack', 'Electronic cigarettes/vaping'
  ];

  String? _selectedAlcoholIntake;
  final List<String> _alcoholOptions = [
    'Non-drinker', '1-3 standard drinks', '4-7 standard drinks', '8-14 standard drinks', '15+ standard drinks'
  ];

  String? _selectedDietaryHabitGeneral;
  final List<String> _dietaryHabitOptions = [
    'Non-specific diet', 'Balanced meals', 'Frequent Fast Food', 'Specific diet plan'
  ];
  final TextEditingController _dietaryHabitsSpecificPlanController = TextEditingController();

  String? _selectedPhysicalActivityLevel;
  final List<String> _physicalActivityOptions = [
    'Inactive (No regular physical activity or structured exercise)',
    'Lightly active (Light physical activities such as walking or leisurely cycling)',
    'Moderately active (Regular moderate exercises like running, swimming, or playing sports)',
    'Very active (Frequent intense physical activities, like workouts or competitive sports)'
  ];

  String? _selectedSleepPattern;
  final List<String> _sleepPatternOptions = [
    '7-9 hours', 'Less than 6 hours', 'More than 9 hours', 'Varies significantly or interrupted sleep'
  ];

  String? _selectedStressLevel;
  final List<String> _stressLevelOptions = [
    'Rarely stressed', 'Manageable stress', 'Regular (daily) stress', 'Almost always stressed'
  ];

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _ageController.dispose();
    _chronicConditionsOtherController.dispose();
    _familyHealthHistoryOtherController.dispose();
    _knownAllergiesOtherController.dispose();
    _surgicalHistoryDetailsController.dispose();
    _currentMedicationsController.dispose();
    _medicationHistoryController.dispose();
    _dietaryHabitsSpecificPlanController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      int errorStep = _findErrorStep();
      if (errorStep != -1 && errorStep != _currentStep) {
        setState(() {
          _currentStep = errorStep;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please review your answers. Some required fields are missing or invalid.'), backgroundColor: AppColors.error),
      );
      return;
    }
    _formKey.currentState!.save();

    setState(() { _isSubmitting = true; });

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Cannot save data.'), backgroundColor: AppColors.error),
      );
      setState(() { _isSubmitting = false; });
      return;
    }

    Map<String, dynamic> patientData = {
      'age': int.tryParse(_ageController.text) ?? 0,
      'healthProfile': {
        'hasChronicConditions': _hasChronicConditions,
        'chronicConditionsSelected': _hasChronicConditions ? _chronicConditionsSelected : _chronicConditionsSelected.map((key, value) => MapEntry(key, false)),
        'chronicConditionsOther': (_hasChronicConditions && _hasOtherChronicConditions) ? _chronicConditionsOtherController.text.trim() : '',

        'hasFamilyHistory': _hasFamilyHistory,
        'familyHealthHistorySelected': _hasFamilyHistory ? _familyHealthHistorySelected : _familyHealthHistorySelected.map((key, value) => MapEntry(key, false)),
        'familyHealthHistoryOther': (_hasFamilyHistory && _hasOtherFamilyHistory) ? _familyHealthHistoryOtherController.text.trim() : '',

        'hasAllergies': _hasAllergies,
        'knownAllergiesSelected': _hasAllergies ? _knownAllergiesSelected : _knownAllergiesSelected.map((key, value) => MapEntry(key, false)),
        'knownAllergiesOther': (_hasAllergies && _hasOtherAllergies) ? _knownAllergiesOtherController.text.trim() : '',

        'hasSurgicalHistory': _hasSurgicalHistory,
        'surgicalHistory': _hasSurgicalHistory ? (_surgicalHistoryDetailsController.text.trim().isEmpty ? 'Details not provided' : _surgicalHistoryDetailsController.text.trim()) : 'None',

        'takingCurrentMedications': _takingCurrentMedications,
        'currentMedications': _takingCurrentMedications ? (_currentMedicationsController.text.trim().isEmpty ? 'None specified' : _currentMedicationsController.text.trim()) : 'None',

        'hasMedicationHistory': _hasMedicationHistory,
        'medicationHistoryLast6Months': _hasMedicationHistory ? (_medicationHistoryController.text.trim().isEmpty ? 'None specified' : _medicationHistoryController.text.trim()) : 'None',
      },
      'lifePatternsHabits': {
        'smokingIntensity': _selectedSmokingIntensity ?? 'Not specified',
        'alcoholIntake': _selectedAlcoholIntake ?? 'Not specified',
        'dietaryHabitsGeneral': _selectedDietaryHabitGeneral ?? 'Not specified',
        'dietaryHabitsSpecificPlanDetails': _selectedDietaryHabitGeneral == 'Specific diet plan'
            ? _dietaryHabitsSpecificPlanController.text.trim()
            : '',
        'physicalActivityLevel': _selectedPhysicalActivityLevel ?? 'Not specified',
        // 'physicalActivityDescription' is removed as per your request
        'sleepPattern': _selectedSleepPattern ?? 'Not specified',
        'stressLevel': _selectedStressLevel ?? 'Not specified',
      },
      'lastUpdated': FieldValue.serverTimestamp(),
      'userId': _currentUser!.uid,
    };

    try {
      await _firestore.collection('patients').doc(_currentUser!.uid).set(patientData, SetOptions(merge: true));
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
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  int _findErrorStep() {
    // Basic check, can be made more sophisticated
    if (_ageController.text.isEmpty || (int.tryParse(_ageController.text) ?? 0) <= 0) return 0;
    // Add more checks for other steps if needed for direct navigation to error
    return -1; // No obvious error found by this basic check
  }


  void _nextStep() {
    // It's better to validate per step if possible, but for now, validate on final submit
    // if (_formKey.currentState!.validate()) { // This would validate all steps
    if (_currentStep < getSteps().length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _saveData(); // SaveData now includes validation
    }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please complete the current step before proceeding.'), backgroundColor: AppColors.warning),
    //   );
    // }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  List<Step> getSteps() {
    return [
      Step(
        title: const Text('Basic Information'),
        content: _buildAgeStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Health Profile - Conditions'),
        content: _buildChronicConditionsStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Health Profile - Family & Allergies'),
        content: _buildFamilyAndAllergiesStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Health Profile - Medical History'),
        content: _buildMedicalHistoryStep(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Lifestyle - Habits'),
        content: _buildHabitsStep(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Lifestyle - Activity & Diet'),
        content: _buildActivityAndDietStep(),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Lifestyle - Sleep & Stress'),
        content: _buildSleepAndStressStep(),
        isActive: _currentStep >= 6,
        state: _currentStep > 6 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  // --- Step Builder Methods ---

  Widget _buildAgeStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.cake_outlined, title: "Your Age"),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: _inputDecoration(labelText: 'Age', hintText: 'e.g., 30'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your age.';
                final age = int.tryParse(value);
                if (age == null || age <= 0 || age > 120) {
                  return 'Please enter a valid age (1-120).';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronicConditionsStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.medical_information_outlined, title: "Chronic & Past Conditions"),
            const SizedBox(height: 16),
            _buildExpandableField( // Main Yes/No for the whole section
              question: "Do you have any chronic or significant past health conditions?",
              hasContent: _hasChronicConditions,
              onChanged: (value) => setState(() {
                _hasChronicConditions = value;
                if (!value) { // If "No", clear sub-selections
                  _chronicConditionsSelected.updateAll((key, val) => false);
                  _hasOtherChronicConditions = false;
                  _chronicConditionsOtherController.clear();
                }
              }),
              showDivider: false, // No divider before the checkboxes if "Yes"
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("Please select from common conditions:", style: Theme.of(context).textTheme.titleSmall),
                  ..._buildCheckboxList(
                    options: _chronicConditionsSelected,
                    onChanged: (key, value) {
                      setState(() { _chronicConditionsSelected[key] = value!; });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildExpandableField( // Nested Yes/No for "Other"
                    question: "Any other chronic conditions to specify?",
                    hasContent: _hasOtherChronicConditions,
                    onChanged: (value) => setState(() => _hasOtherChronicConditions = value),
                    child: TextFormField(
                      controller: _chronicConditionsOtherController,
                      decoration: _inputDecoration(
                        labelText: 'Other conditions/details',
                        hintText: 'e.g., Asthma, High blood pressure for 5 years.',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (_hasOtherChronicConditions && (value == null || value.isEmpty)) {
                          return 'Please provide details or select "No".';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyAndAllergiesStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.family_restroom_outlined, title: "Family Health History"),
            const SizedBox(height: 16),
            _buildExpandableField( // Main Yes/No for Family History
              question: "Is there any significant health history in your immediate family?",
              hasContent: _hasFamilyHistory,
              onChanged: (value) => setState(() {
                _hasFamilyHistory = value;
                if (!value) {
                  _familyHealthHistorySelected.updateAll((key, val) => false);
                  _hasOtherFamilyHistory = false;
                  _familyHealthHistoryOtherController.clear();
                }
              }),
              showDivider: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("Please select from common family conditions:", style: Theme.of(context).textTheme.titleSmall),
                  ..._buildCheckboxList(
                    options: _familyHealthHistorySelected,
                    onChanged: (key, value) {
                      setState(() { _familyHealthHistorySelected[key] = value!; });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildExpandableField( // Nested Yes/No for "Other Family History"
                    question: "Any other family health history to specify?",
                    hasContent: _hasOtherFamilyHistory,
                    onChanged: (value) => setState(() => _hasOtherFamilyHistory = value),
                    child: TextFormField(
                      controller: _familyHealthHistoryOtherController,
                      decoration: _inputDecoration(
                        labelText: 'Other family history details',
                        hintText: 'e.g., Mother with Type 2 Diabetes, Sibling with asthma.',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (_hasOtherFamilyHistory && (value == null || value.isEmpty)) {
                          return 'Please provide details or select "No".';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Space between sections
            const SectionHeader(icon: Icons.warning_amber_rounded, title: "Known Allergies"),
            const SizedBox(height: 16),
            _buildExpandableField( // Main Yes/No for Allergies
              question: "Do you have any known allergies?",
              hasContent: _hasAllergies,
              onChanged: (value) => setState(() {
                _hasAllergies = value;
                if (!value) {
                  _knownAllergiesSelected.updateAll((key, val) => false);
                  _hasOtherAllergies = false;
                  _knownAllergiesOtherController.clear();
                }
              }),
              showDivider: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("Please select from common allergies:", style: Theme.of(context).textTheme.titleSmall),
                  ..._buildCheckboxList(
                    options: _knownAllergiesSelected,
                    onChanged: (key, value) {
                      setState(() { _knownAllergiesSelected[key] = value!; });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildExpandableField( // Nested Yes/No for "Other Allergies"
                    question: "Any other allergies to specify?",
                    hasContent: _hasOtherAllergies,
                    onChanged: (value) => setState(() => _hasOtherAllergies = value),
                    child: TextFormField(
                      controller: _knownAllergiesOtherController,
                      decoration: _inputDecoration(
                        labelText: 'Other allergies/details',
                        hintText: 'e.g., Penicillin allergy, Dust mites.',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (_hasOtherAllergies && (value == null || value.isEmpty)) {
                          return 'Please provide details or select "No".';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.history_edu_outlined, title: "Surgical & Medication History"),
            const SizedBox(height: 16),
            _buildExpandableField(
              question: "Have you had any surgeries?",
              hasContent: _hasSurgicalHistory,
              onChanged: (value) => setState(() => _hasSurgicalHistory = value),
              child: TextFormField(
                controller: _surgicalHistoryDetailsController,
                decoration: _inputDecoration(
                  labelText: 'Details of surgeries (name and approximate year)',
                  hintText: 'e.g., Appendectomy in 2003, Cardiac stenting in 2019.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (_hasSurgicalHistory && (value == null || value.isEmpty)) {
                    return 'Please provide surgery details or select "No".';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildExpandableField(
              question: "Are you currently taking any medications (including supplements, OTC)?",
              hasContent: _takingCurrentMedications,
              onChanged: (value) => setState(() => _takingCurrentMedications = value),
              child: TextFormField(
                controller: _currentMedicationsController,
                decoration: _inputDecoration(
                  labelText: 'List current medications and dosage',
                  hintText: 'e.g., Metformin 500mg twice daily, Vitamin D 1000IU daily.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (_takingCurrentMedications && (value == null || value.isEmpty)) {
                    return 'Please list medications or select "No".';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildExpandableField(
              question: "Have you taken any significant medications in the last 6 months?",
              hasContent: _hasMedicationHistory,
              onChanged: (value) => setState(() => _hasMedicationHistory = value),
              child: TextFormField(
                controller: _medicationHistoryController,
                decoration: _inputDecoration(
                  labelText: 'List medications taken in last 6 months',
                  hintText: 'e.g., Amoxicillin for 7 days (Feb), Ibuprofen as needed.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (_hasMedicationHistory && (value == null || value.isEmpty)) {
                    return 'Please list medications or select "No".';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.smoking_rooms_outlined, title: "Smoking & Alcohol"),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'Daily smoking intensity',
              value: _selectedSmokingIntensity,
              items: _smokingOptions,
              onChanged: (value) => setState(() => _selectedSmokingIntensity = value),
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
            const SizedBox(height: 20),
            _buildDropdownFormField(
              label: 'Weekly alcohol intake',
              value: _selectedAlcoholIntake,
              items: _alcoholOptions,
              onChanged: (value) => setState(() => _selectedAlcoholIntake = value),
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityAndDietStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.restaurant_menu_outlined, title: "Dietary Habits"),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'General dietary habits',
              value: _selectedDietaryHabitGeneral,
              items: _dietaryHabitOptions,
              onChanged: (value) => setState(() => _selectedDietaryHabitGeneral = value),
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
            if (_selectedDietaryHabitGeneral == 'Specific diet plan') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _dietaryHabitsSpecificPlanController,
                decoration: _inputDecoration(
                    labelText: 'Details of your specific diet plan',
                    hintText: 'e.g., Keto, High-protein, Vegan, Low-sodium.'),
                validator: (value) {
                  if (_selectedDietaryHabitGeneral == 'Specific diet plan' && (value == null || value.isEmpty)) {
                    return 'Please specify your diet plan details.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.fitness_center_outlined, title: "Physical Activity"),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'Weekly physical activity level',
              value: _selectedPhysicalActivityLevel,
              items: _physicalActivityOptions,
              onChanged: (value) => setState(() => _selectedPhysicalActivityLevel = value),
              itemHeight: 70,
              isExpanded: true, // Allow dropdown to expand for long text
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
            // TextFormField for physical activity description has been removed as per your request.
          ],
        ),
      ),
    );
  }

  Widget _buildSleepAndStressStep() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.bedtime_outlined, title: "Sleep Pattern"),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'Average daily sleep pattern',
              value: _selectedSleepPattern,
              items: _sleepPatternOptions,
              onChanged: (value) => setState(() => _selectedSleepPattern = value),
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
            const SizedBox(height: 24),
            const SectionHeader(icon: Icons.sentiment_very_dissatisfied_outlined, title: "Stress Level"),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              label: 'General stress level',
              value: _selectedStressLevel,
              items: _stressLevelOptions,
              onChanged: (value) => setState(() => _selectedStressLevel = value),
              validator: (value) => value == null ? 'This field is required.' : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (from your provided code, slightly restyled) ---
  List<Widget> _buildCheckboxList({
    required Map<String, bool> options,
    required Function(String, bool?) onChanged,
  }) {
    return options.keys.map((key) {
      return Card(
        elevation: 0.5,
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: options[key]! ? AppColors.primary.withOpacity(0.7) : AppColors.gray.withOpacity(0.3), width: 0.8),
        ),
        child: CheckboxListTile(
          title: Text(key, style: TextStyle(color: AppColors.dark.withOpacity(0.9))),
          value: options[key],
          onChanged: (value) => onChanged(key, value),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      );
    }).toList();
  }

  Widget _buildYesNoToggle({
    required bool currentValue,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: MaterialButton(
            onPressed: () => onChanged(true),
            color: currentValue ? AppColors.primary : AppColors.light,
            textColor: currentValue ? Colors.white : AppColors.dark,
            elevation: currentValue ? 2 : 0.5,
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                side: BorderSide(color: currentValue ? AppColors.primary : AppColors.gray.withOpacity(0.5))
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('YES'),
          ),
        ),
        Expanded(
          child: MaterialButton(
            onPressed: () => onChanged(false),
            color: !currentValue ? AppColors.primary : AppColors.light,
            textColor: !currentValue ? Colors.white : AppColors.dark,
            elevation: !currentValue ? 2 : 0.5,
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                side: BorderSide(color: !currentValue ? AppColors.primary : AppColors.gray.withOpacity(0.5))
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableField({
    required String question,
    required bool hasContent, // This is the Yes/No state
    required Function(bool) onChanged, // To change the Yes/No state
    required Widget child, // The TextFormField or other widget to show if Yes
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildYesNoToggle(
          currentValue: hasContent,
          onChanged: onChanged,
        ),
        if (hasContent) ...[
          const SizedBox(height: 12),
          // if (showDivider) const Divider(thickness: 0.8),
          // if (showDivider) const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          ),
        ],
        if (showDivider) const SizedBox(height: 16),
        if (showDivider) const Divider(thickness: 0.7),
        if (showDivider) const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildDropdownFormField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    double? itemHeight, // e.g., 70 or 80 for multi-line items
    bool isExpanded = false, // Default to false, set true for long item texts
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration(), // Using the shared input decoration
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              // Wrap the Text widget with Expanded or Flexible if it's inside a Row,
              // or ensure the DropdownButtonFormField itself has enough width.
              // For long items in the dropdown list itself:
              child: Text(
                item,
                overflow: TextOverflow.ellipsis, // Handles overflow for the displayed selected item
                maxLines: isExpanded ? 3 : 1, // Allow more lines if the item text is long and isExpanded is true
                softWrap: isExpanded,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: isExpanded, // This makes the dropdown button expand to fill available horizontal space.
          // For the items in the dropdown list, their width is constrained by the dropdown menu's width.
          icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary),
          itemHeight: itemHeight, // Use null for default, or specify e.g. kMinInteractiveDimension * 1.5 for taller items
          dropdownColor: Colors.white,
          style: TextStyle(color: AppColors.dark, fontSize: 15, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String labelText = '', String hintText = ''}) {
    return InputDecoration(
      labelText: labelText.isNotEmpty ? labelText : null,
      hintText: hintText,
      labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.8), fontSize: 15),
      hintStyle: TextStyle(color: AppColors.gray, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.gray.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: AppColors.gray.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      filled: true,
      fillColor: AppColors.white, // Or AppColors.light.withOpacity(0.7)
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Questionnaire', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isSubmitting
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary)),
            const SizedBox(height: 20),
            Text('Saving your responses...', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dark)),
          ],
        ),
      )
          : Container(
        // decoration: BoxDecoration( // Optional: Add a subtle background
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: [AppColors.light.withOpacity(0.3), AppColors.white, AppColors.light.withOpacity(0.3)],
        //   ),
        // ),
        child: Form(
          key: _formKey,
          child: Stepper(
            physics: const ClampingScrollPhysics(),
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _prevStep,
            steps: getSteps(),
            controlsBuilder: (context, ControlsDetails controls) {
              final isLastStep = _currentStep == getSteps().length - 1;
              final isFirstStep = _currentStep == 0;

              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0, left: 8.0, right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isFirstStep)
                      OutlinedButton.icon(
                        onPressed: controls.onStepCancel,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: const Text('BACK'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else
                      const SizedBox(width: 80), // Placeholder for alignment

                    ElevatedButton.icon(
                      onPressed: controls.onStepContinue,
                      icon: Icon(isLastStep ? Icons.check_circle_outline : Icons.arrow_forward_ios, size: 18),
                      label: Text(isLastStep ? 'SUBMIT ANSWERS' : 'NEXT STEP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// Section Header Component (as you defined it, slightly styled)
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0), // Reduced bottom padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded( // Allow title to wrap if too long
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                // fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
