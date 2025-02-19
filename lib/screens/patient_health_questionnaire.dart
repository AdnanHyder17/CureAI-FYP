// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homeScreen.dart';
import 'package:p1/theme.dart';

class PatientHealthQuestionnaire extends StatefulWidget {
  const PatientHealthQuestionnaire({super.key});

  @override
  _PatientHealthQuestionnaireState createState() => _PatientHealthQuestionnaireState();
}

class _PatientHealthQuestionnaireState extends State<PatientHealthQuestionnaire> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // User data variables
  int _age = 0;
  String _chronicConditions = 'None';
  String _familyHealthHistory = 'None';
  String _knownAllergies = 'None';
  String _currentMedications = 'None';
  String _medicationHistory = 'None';
  String _smokingIntensity = '';
  String _physicalActivityLevel = '';
  String _sleepPattern = '';
  String _stressLevel = '';

  // Stepper control
  int _currentStep = 0;
  bool _complete = false;

  // Lists of options
  final List<String> smokingOptions = ['Non-smoker', 'Occasional', 'Regular', 'Heavy',];
  final List<String> activityLevels = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active',];
  final List<String> sleepPatterns = ['Less than 5 hours', '5-7 hours', '7-9 hours', 'More than 9 hours',];
  final List<String> stressLevels = ['Low', 'Moderate', 'High', 'Very High',];

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Save data to Firestore
  Future<void> _saveData() async {
    try {
      await _firestore.collection('patients').doc(_currentUser?.uid).set({
        'age': _age,
        'chronicConditions': _chronicConditions,
        'familyHealthHistory': _familyHealthHistory,
        'knownAllergies': _knownAllergies,
        'currentMedications': _currentMedications,
        'medicationHistory': _medicationHistory,
        'smokingIntensity': _smokingIntensity,
        'physicalActivityLevel': _physicalActivityLevel,
        'sleepPattern': _sleepPattern,
        'stressLevel': _stressLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save data. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _nextStep() {
    final currentStepValid = _formKey.currentState?.validate() ?? false;

    if (currentStepValid) {
      _formKey.currentState?.save();
      if (_currentStep < getSteps().length - 1) {
        setState(() => _currentStep += 1);
      } else {
        setState(() => _complete = true);
        _saveData().then((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
          );
        });
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  List<Step> getSteps() {
    return [
      // Step 1: Age
      Step(
        title: Text('Age', style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To personalize your experience, please enter your age.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                hintText: 'e.g., 30',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (_currentStep != 0) return null; // Only validate in Step 0
                if (value == null || value.isEmpty) return 'Please enter your age.';
                if (int.tryParse(value) == null) return 'Please enter a valid number.';
                return null;
              },
              onSaved: (value) => _age = int.parse(value!),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),

      // Step 2: Chronic Health Conditions
      Step(
        title: Text('Chronic Health Conditions', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you have any chronic or past health conditions?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            _buildYesNoToggle(
              onYes: () => setState(() => _chronicConditions = ''),
              onNo: () => setState(() => _chronicConditions = 'None'),
              isYesSelected: _chronicConditions.isEmpty,
              isNoSelected: _chronicConditions == 'None',
            ),
            SizedBox(height: 20),
            if (_chronicConditions.isEmpty)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Please list them here',
                  hintText: 'e.g., Diabetes, Hypertension',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (_currentStep != 1) return null; // Only validate in Step 1
                  if (_chronicConditions.isEmpty && (value == null || value.isEmpty)) {
                    return 'Please list your conditions.';
                  }
                  return null;
                },
                onSaved: (value) => _chronicConditions = value ?? 'None',
              ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),

      // Step 3: Family Health History
      Step(
        title: Text('Family Health History', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Any significant family health history?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            _buildYesNoToggle(
              onYes: () => setState(() => _familyHealthHistory = ''),
              onNo: () => setState(() => _familyHealthHistory = 'None'),
              isYesSelected: _familyHealthHistory.isEmpty,
              isNoSelected: _familyHealthHistory == 'None',
            ),
            SizedBox(height: 20),
            if (_familyHealthHistory.isEmpty)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Please describe',
                  hintText: 'e.g., Heart disease, Cancer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (_currentStep != 2) return null; // Only validate in Step 2
                  if (_familyHealthHistory.isEmpty && (value == null || value.isEmpty)) {
                    return 'Please provide details.';
                  }
                  return null;
                },
                onSaved: (value) => _familyHealthHistory = value ?? 'None',
              ),
          ],
        ),
        isActive: _currentStep >= 2,
      ),

      // Step 4: Known Allergies
      Step(
        title: Text('Known Allergies', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you have any known allergies?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            _buildYesNoToggle(
              onYes: () => setState(() => _knownAllergies = ''),
              onNo: () => setState(() => _knownAllergies = 'None'),
              isYesSelected: _knownAllergies.isEmpty,
              isNoSelected: _knownAllergies == 'None',
            ),
            SizedBox(height: 20),
            if (_knownAllergies.isEmpty)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'e.g., Peanuts, Penicillin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (_currentStep != 3) return null; // Only validate in Step 3
                  if (_knownAllergies.isEmpty && (value == null || value.isEmpty)) {
                    return 'Please list your allergies.';
                  }
                  return null;
                },
                onSaved: (value) => _knownAllergies = value ?? 'None',
              ),
          ],
        ),
        isActive: _currentStep >= 3,
      ),

      // Step 5: Current Medications
      Step(
        title: Text('Current Medications', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you currently taking any medications?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            _buildYesNoToggle(
              onYes: () => setState(() => _currentMedications = ''),
              onNo: () => setState(() => _currentMedications = 'None'),
              isYesSelected: _currentMedications.isEmpty,
              isNoSelected: _currentMedications == 'None',
            ),
            SizedBox(height: 20),
            if (_currentMedications.isEmpty)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Medications',
                  hintText: 'e.g., Metformin, Lisinopril',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (_currentStep != 4) return null; // Only validate in Step 4
                  if (_currentMedications.isEmpty && (value == null || value.isEmpty)) {
                    return 'Please list your medications.';
                  }
                  return null;
                },
                onSaved: (value) => _currentMedications = value ?? 'None',
              ),
          ],
        ),
        isActive: _currentStep >= 4,
      ),

      // Step 6: Medication History (Last 6 months)
      Step(
        title: Text('Medication History', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have you taken any medications in the last 6 months?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            _buildYesNoToggle(
              onYes: () => setState(() => _medicationHistory = ''),
              onNo: () => setState(() => _medicationHistory = 'None'),
              isYesSelected: _medicationHistory.isEmpty,
              isNoSelected: _medicationHistory == 'None',
            ),
            SizedBox(height: 20),
            if (_medicationHistory.isEmpty)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Past Medications',
                  hintText: 'e.g., Antibiotics, Painkillers',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (_currentStep != 5) return null; // Only validate in Step 5
                  if (_medicationHistory.isEmpty && (value == null || value.isEmpty)) {
                    return 'Please list your past medications.';
                  }
                  return null;
                },
                onSaved: (value) => _medicationHistory = value ?? 'None',
              ),
          ],
        ),
        isActive: _currentStep >= 5,
      ),

      // Step 7: Daily Smoking Intensity
      Step(
        title: Text('Smoking Intensity', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How often do you smoke?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Smoking Intensity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: _smokingIntensity.isNotEmpty ? _smokingIntensity : null,
              items: smokingOptions.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() => _smokingIntensity = value ?? '');
              },
              validator: (value) {
                if (_currentStep != 6) return null; // Only validate in Step 6
                if (value == null || value.isEmpty) return 'Please select an option.';
                return null;
              },
              onSaved: (value) => _smokingIntensity = value ?? '',
            ),
          ],
        ),
        isActive: _currentStep >= 6,
      ),

      // Step 8: Weekly Physical Activity Level
      Step(
        title: Text('Physical Activity Level', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How active are you on a weekly basis?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: _physicalActivityLevel.isNotEmpty
                  ? _physicalActivityLevel
                  : null,
              items: activityLevels.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() => _physicalActivityLevel = value ?? '');
              },
              validator: (value) {
                if (_currentStep != 7) return null; // Only validate in Step 7
                if (value == null || value.isEmpty) return 'Please select an option.';
                return null;
              },
              onSaved: (value) => _physicalActivityLevel = value ?? '',
            ),
          ],
        ),
        isActive: _currentStep >= 7,
      ),

      // Step 9: Daily Sleep Pattern
      Step(
        title: Text('Sleep Pattern', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How much sleep do you get on average each night?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Sleep Pattern',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: _sleepPattern.isNotEmpty ? _sleepPattern : null,
              items: sleepPatterns.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() => _sleepPattern = value ?? '');
              },
              validator: (value) {
                if (_currentStep != 8) return null; // Only validate in Step 8
                if (value == null || value.isEmpty) return 'Please select an option.';
                return null;
              },
              onSaved: (value) => _sleepPattern = value ?? '',
            ),
          ],
        ),
        isActive: _currentStep >= 8,
      ),

      // Step 10: Stress Level
      Step(
        title: Text('Stress Level', style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you rate your current level of stress?',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Stress Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: _stressLevel.isNotEmpty ? _stressLevel : null,
              items: stressLevels.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() => _stressLevel = value ?? '');
              },
              validator: (value) {
                if (_currentStep != 9) return null; // Only validate in Step 9
                if (value == null || value.isEmpty) return 'Please select an option.';
                return null;
              },
              onSaved: (value) => _stressLevel = value ?? '',
            ),
          ],
        ),
        isActive: _currentStep >= 9,
      ),
    ];
  }

  // Helper method to build Yes/No toggle
  Widget _buildYesNoToggle({
    required VoidCallback onYes,
    required VoidCallback onNo,
    required bool isYesSelected,
    required bool isNoSelected,
  }) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: onYes,
          style: ElevatedButton.styleFrom(
            backgroundColor: isYesSelected ? AppColors.primary : AppColors.gray,
            foregroundColor: AppColors.white,
          ),
          child: Text('Yes'),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: onNo,
          style: ElevatedButton.styleFrom(
            backgroundColor: isNoSelected ? AppColors.primary : AppColors.gray,
            foregroundColor: AppColors.white,
          ),
          child: Text('No'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Questionnaire', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppColors.primary,
      ),
      body: _complete
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
            SizedBox(height: 20),
            Text('Saving your responses...', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      )
          : Form(
        key: _formKey, // Ensure the Form has a key
        child: Stepper(
          physics: ClampingScrollPhysics(),
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _nextStep, // Ensure this is set
          onStepCancel: _prevStep, // Ensure this is set
          steps: getSteps(),
          controlsBuilder: (context, ControlsDetails controls) {
            final isLastStep = _currentStep == getSteps().length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: controls.onStepContinue, // Ensure this is set
                    child: Text(isLastStep ? 'Submit' : 'Next'),
                  ),
                  SizedBox(width: 16),
                  if (_currentStep != 0)
                    OutlinedButton(
                      onPressed: controls.onStepCancel, // Ensure this is set
                      child: Text('Back'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}