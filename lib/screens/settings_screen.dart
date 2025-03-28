import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../data/user_data.dart';
import '../theme.dart';
import './admin/admin_panel_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (firebaseUser != null && firebaseUser!.uid.isNotEmpty) {
      await loadUserFromFirestore(firebaseUser!.uid);
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Option
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text(
                "Profile",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white38),

            // ✅ Admin Panel (safe with loaded currentUser)
            if (currentUser?.isAdmin == true)
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.amber,
                ),
                title: const Text(
                  "Admin Panel",
                  style: TextStyle(color: Colors.amber, fontSize: 16),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  );
                },
              ),

            if (currentUser?.isAdmin == true)
              const Divider(color: Colors.white38),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
