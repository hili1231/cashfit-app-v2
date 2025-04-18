import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/nav_screen.dart';
import '../providers/user_provider.dart';

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
  final AuthService auth = AuthService();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Store userProvider before the async operation
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = await auth.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim(),
      );

      if (user != null) {
        await userProvider.loadUserData(
          user.uid,
        ); // Use the stored userProvider
        if (mounted) {
          // Guard context usage with mounted check
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
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message ?? 'Registration failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildInputField(
                    "Name",
                    nameController,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  _buildInputField(
                    "Email",
                    emailController,
                    keyboardType: TextInputType.emailAddress,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  _buildInputField(
                    "Password",
                    passwordController,
                    isPassword: true,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        colorScheme.onPrimary,
                      ),
                    ),
                    onPressed: isLoading ? null : registerUser,
                    child:
                        isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : Text(
                              "Register",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                  ),
                ],
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
    required ColorScheme colorScheme,
    required ThemeData theme,
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
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
