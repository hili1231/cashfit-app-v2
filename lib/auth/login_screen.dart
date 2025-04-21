import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/nav_screen.dart';
import '../auth/register_screen.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final forgotPasswordEmailController = TextEditingController();
  final AuthService auth = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;
  String errorMessage = '';

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    // Store UserProvider before async operation
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = await auth.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        await userProvider.loadUserData(user.uid);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => const NavScreen(),
              transitionsBuilder: (_, animation, __, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                );
                return FadeTransition(opacity: curved, child: child);
              },
            ),
          );
        }
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

  Future<void> signInWithSocial(String provider) async {
    // Store UserProvider before async operation
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      User? user;
      switch (provider) {
        case 'google':
          user = await auth.signInWithGoogle();
          break;
        case 'apple':
          user = await auth.signInWithApple();
          break;
        case 'facebook':
          user = await auth.signInWithFacebook();
          break;
      }

      if (user != null) {
        await userProvider.loadUserData(user.uid);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => const NavScreen(),
              transitionsBuilder: (_, animation, __, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                );
                return FadeTransition(opacity: curved, child: child);
              },
            ),
          );
        }
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

  // Forgot Password Method
  Future<void> _forgotPassword() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Store the ScaffoldMessengerState from the parent context
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show dialog to enter email
    await showDialog(
      context: context,
      builder: (dialogContext) {
        // Store NavigatorState for the dialog context
        final dialogNavigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: Text(
            "Forgot Password",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextFormField(
            controller: forgotPasswordEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
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
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter email";
              if (!v.contains('@')) return "Invalid email format";
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => dialogNavigator.pop(),
              child: Text(
                "Cancel",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () async {
                final email = forgotPasswordEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      backgroundColor: colorScheme.error,
                      content: Text(
                        "Please enter a valid email address",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  dialogNavigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      backgroundColor: colorScheme.primary,
                      content: Text(
                        "Password reset email sent to $email",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      backgroundColor: colorScheme.error,
                      content: Text(
                        "Failed to send reset email: ${e.toString()}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                "Send Reset Email",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Clear the controller after dialog is closed
    forgotPasswordEmailController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    forgotPasswordEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Login",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter email";
                    if (!v.contains('@')) return "Invalid email format";
                    return null;
                  },
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: "Email",
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  validator:
                      (v) => v == null || v.isEmpty ? "Enter password" : null,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: "Password",
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      "Forgot Password?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                  onPressed: isLoading ? null : login,
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
                            "Login",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Or sign in with",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.g_mobiledata,
                        color: colorScheme.onSurface,
                        size: 40,
                      ),
                      onPressed:
                          isLoading ? null : () => signInWithSocial('google'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.apple,
                        color: colorScheme.onSurface,
                        size: 40,
                      ),
                      onPressed:
                          isLoading ? null : () => signInWithSocial('apple'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.facebook,
                        color: colorScheme.onSurface,
                        size: 40,
                      ),
                      onPressed:
                          isLoading ? null : () => signInWithSocial('facebook'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    "Register Here",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
