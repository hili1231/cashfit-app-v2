import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/user_data.dart';
import '../models/app_user.dart';
import '../theme.dart';
import '../screens/nav_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = credential.user;

      // Build extended AppUser instance
      currentUser = AppUser(
        id: user?.uid ?? '',
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        avatar: "assets/images/avatar.png",
        workoutsCompleted: 0,
        mealsTracked: 0,
        gender: '',
        age: '',
        height: '',
        weight: '',
        activityLevel: '',
        dietGoal: '',
        dietPreference: '',
        workoutGoal: '',
        experienceLevel: '',
        trainingStyle: '',
        availableEquipment: [],
        injuryHistory: [],
        workoutFrequency: 0,
        allergies: [],
        isAdmin: false,
        isPremium: false,
        activeWorkoutPrograms: [],
        activeDietPlans: [],
      );

      // Save the user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .set(currentUser!.toMap());

      // Reload user data from Firestore to ensure currentUser is updated
      await loadUserFromFirestore(currentUser!.id);

      // Optionally, send email verification
      await user?.sendEmailVerification();

      if (mounted) {
        // Navigate to NavScreen (or clear detail screen if available)
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.clearDetailScreen();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NavScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Registration failed';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset('assets/images/logo.png', height: 60),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Create Account",
                      style: AppTheme.headline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildInputField("Name", nameController),
                    _buildInputField(
                      "Email",
                      emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildInputField(
                      "Password",
                      passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: AppTheme.buttonStyle,
                      onPressed: isLoading ? null : registerUser,
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                              : const Text("Register"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        autofillHints:
            isPassword ? [AutofillHints.newPassword] : [AutofillHints.email],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter $label';
          }
          if (label == "Email" && !value.contains('@')) {
            return 'Invalid email';
          }
          if (label == "Password" && value.length < 6) {
            return 'Minimum 6 characters';
          }
          return null;
        },
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }
}
