// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'homeScreen.dart';
import 'package:p1/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });
      try {
        UserCredential _ = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CureAI Login',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/logo.png',
                height: 250,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              // Text(
              //   'Welcome Back!',
              //   textAlign: TextAlign.center,
              //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              //     fontWeight: FontWeight.bold,
              //     color: AppColors.primary,
              //   ),
              // ),
              // const SizedBox(height: 20),
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: AppColors.dark),
                        prefixIcon: Icon(Icons.email, color: AppColors.secondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter email' : null,
                      onChanged: (value) => email = value,
                    ),
                    const SizedBox(height: 15),
                    // Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: AppColors.dark),
                        prefixIcon: Icon(Icons.lock, color: AppColors.secondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter password' : null,
                      onChanged: (value) => password = value,
                    ),
                    const SizedBox(height: 25),
                    // Login Button
                    isLoading
                        ? CircularProgressIndicator(color: AppColors.secondary)
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Sign Up Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignupScreen()),
                        );
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


