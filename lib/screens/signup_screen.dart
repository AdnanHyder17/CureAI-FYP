// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p1/screens/role_specific_welcome_screen.dart';
import 'package:p1/theme.dart';
import 'package:p1/widgets/custom_textfield.dart'; // Reusing
import 'package:p1/widgets/loading_indicator.dart'; // Reusing
import 'package:dropdown_search/dropdown_search.dart'; // Kept for consistency if you like this UX

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedCountry;
  String? _selectedRole;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of countries - consider moving to a constants file if used elsewhere
  final List<String> _countries = [
    'United States', 'India', 'United Kingdom', 'Canada', 'Australia', 'Germany',
    'France', 'Pakistan', 'China', 'Japan', 'Brazil', 'Italy', 'Mexico', 'Spain',
    'Russia', 'Netherlands', 'South Africa', 'Argentina', 'Other'
    // Add more or fetch dynamically
  ];
  final List<String> _roles = ['Patient', 'Doctor'];

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role.'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;
      if (newUser != null) {
        // Store user details in Firestore
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'nickname': _nicknameController.text.trim(),
          'nickname_lowercase': _nicknameController.text.trim().toLowerCase(), // For searching
          'email': _emailController.text.trim(),
          'country': _selectedCountry,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'profileImageUrl': null, // Initialize with null
          'isProfileSetupComplete': false,
        });

        // Create an empty profile document for the role to signify profile is not yet complete
        if (_selectedRole == 'Doctor') {
          await _firestore.collection('doctors').doc(newUser.uid).set({
            'uid': newUser.uid,
            'email': _emailController.text.trim(), // Denormalize for easy access
            'nickname': _nicknameController.text.trim(),
            'nickname_lowercase': _nicknameController.text.trim().toLowerCase(),
            'status': 'offline', // Default status
            'callStatus': 'unavailable', // Default call status
            'createdAt': FieldValue.serverTimestamp(),
            // Other fields will be added in DoctorProfessionalDetails
          });
        } else if (_selectedRole == 'Patient') {
          await _firestore.collection('patients').doc(newUser.uid).set({
            'uid': newUser.uid,
            'email': _emailController.text.trim(),
            'nickname': _nicknameController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            // Other fields will be added in PatientHealthQuestionnaire
          });
        }


        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => RoleSpecificWelcomeScreen(
                userRole: _selectedRole!,
                nickname: _nicknameController.text.trim(),
              ),
            ),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Widget _buildDropdownSearch<T>({
    required String labelText,
    required IconData prefixIcon,
    required List<T> items,
    T? selectedItem,
    required ValueChanged<T?> onChanged,
    required String? Function(T?) validator,
    bool showSearchBox = false,
    String? searchHintText,
  }) {
    return DropdownSearch<T>(
      items: items,
      selectedItem: selectedItem,
      onChanged: onChanged,
      validator: validator,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon, color: AppColors.secondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: AppColors.gray.withOpacity(0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          fillColor: AppColors.white.withOpacity(0.8),
          filled: true,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: showSearchBox,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: showSearchBox ? (searchHintText ?? 'Search...') : '',
            prefixIcon: showSearchBox ? const Icon(Icons.search, color: AppColors.secondary) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
        menuProps: MenuProps(
          borderRadius: BorderRadius.circular(12.0),
        ),
        constraints: BoxConstraints(maxHeight: showSearchBox ? 350 : 180),
        itemBuilder: (context, item, isSelected) {
          return ListTile(
            title: Text(
              item.toString(),
              style: TextStyle(color: isSelected ? AppColors.primary : AppColors.dark),
            ),
            selected: isSelected,
            selectedTileColor: AppColors.primary.withOpacity(0.1),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Join CureAI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide a few details to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dark.withOpacity(0.7)),
                ),
                SizedBox(height: screenHeight * 0.04),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      CustomTextField(
                        controller: _nicknameController,
                        labelText: 'Nickname',
                        hintText: 'e.g., John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter your nickname' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownSearch<String>(
                        labelText: 'Country',
                        prefixIcon: Icons.flag_outlined,
                        items: _countries,
                        selectedItem: _selectedCountry,
                        onChanged: (value) => setState(() => _selectedCountry = value),
                        validator: (value) => value == null ? 'Please select your country' : null,
                        showSearchBox: true,
                        searchHintText: 'Search country...',
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownSearch<String>(
                        labelText: 'I am a...',
                        prefixIcon: Icons.cases_outlined,
                        items: _roles,
                        selectedItem: _selectedRole,
                        onChanged: (value) => setState(() => _selectedRole = value),
                        validator: (value) => value == null ? 'Please select your role' : null,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Minimum 6 characters',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.secondary),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.secondary),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const LoadingIndicator()
                          : ElevatedButton(
                        onPressed: _signupUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Already have an account? ", style: TextStyle(color: AppColors.dark.withOpacity(0.8))),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context), // Go back to Login
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Log In', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}