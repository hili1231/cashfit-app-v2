import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import 'register_screen.dart';
import '../screens/nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService auth = AuthService();
  bool isLoading = false;

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await auth.signIn(emailController.text, passwordController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text("Login", style: AppTheme.headline),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    validator: (v) => v!.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? "Enter password" : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: AppTheme.buttonStyle,
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Login"),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                    child: const Text(
                      "Register Here",
                      style: TextStyle(color: AppTheme.gold),
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
}
