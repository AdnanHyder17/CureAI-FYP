// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'patient_welcome_screen.dart';
import 'doctor_welcome_screen.dart';
import 'package:p1/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '', nickname = '';
  String? country, selectedRole;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _countries = [
    'United States', 'India', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Pakistan', 'China', 'Japan', 'Brazil', 'Italy',
    'Mexico', 'Spain', 'Russia', 'Netherlands', 'South Africa', 'Argentina'
  ];

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        String userId = userCredential.user?.uid ?? '';

        await _firestore.collection('users').doc(userId).set({
          'nickname': nickname,
          'email': email,
          'country': country,
          'role': selectedRole,
          'timestamp': FieldValue.serverTimestamp(),
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedRole == 'Patient') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PatientWelcomeScreen(nickname: nickname),
              ),
            );
          } else if (selectedRole == 'Doctor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorWelcomeScreen(nickname: nickname),
              ),
            );
          }
        });
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign Up failed')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CureAI Sign Up'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: isLoading
              ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          )
              : Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Image.asset(
                  'assets/signup.jpg',
                  height: 150,
                ),
                SizedBox(height: 30),
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 20),

                // Nickname
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nickname',
                    prefixIcon: Icon(Icons.person, color: AppColors.secondary),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Enter nickname' : null,
                  onChanged: (value) => nickname = value,
                ),
                SizedBox(height: 20),

                // Searchable and Scrollable Country Dropdown
                DropdownSearch<String>(
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    fit: FlexFit.loose,
                    constraints: BoxConstraints(maxHeight: 300),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'Search country',
                        prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag, color: AppColors.secondary),
                    ),
                  ),
                  items: _countries,
                  onChanged: (value) {
                    setState(() {
                      country = value;
                    });
                  },
                  validator: (value) => value == null ? 'Select a country' : null,
                ),
                SizedBox(height: 20),

                // Searchable and Scrollable Role Dropdown
                DropdownSearch<String>(
                  popupProps: PopupProps.menu(
                    fit: FlexFit.loose,
                    constraints: BoxConstraints(maxHeight: 150),
                  ),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.secondary),
                    ),
                  ),
                  items: ['Patient', 'Doctor'],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                  validator: (value) => value == null ? 'Select a role' : null,
                ),


                SizedBox(height: 20),

                // Email
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: AppColors.secondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) => email = value,
                ),
                SizedBox(height: 20),

                // Password with Visibility Toggle
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: AppColors.secondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.secondary,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  validator: (value) =>
                  value != null && value.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                  onChanged: (value) => password = value,
                ),
                SizedBox(height: 30),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
