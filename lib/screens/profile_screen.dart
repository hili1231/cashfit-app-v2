import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../data/user_data.dart';
import '../theme.dart';
import './settings_screen.dart';
import '../screens/nav_screen.dart'; // ✅ Make sure this is correct path to your NavScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, TextEditingController> controllers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return;
    }

    // Fetch latest user data
    if (currentUser != null && currentUser!.id.isNotEmpty) {
      loadUserFromFirestore(currentUser!.id).then((_) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          controllers['name'] = TextEditingController(
            text: currentUser?.name ?? '',
          );
          controllers['email'] = TextEditingController(
            text: currentUser?.email ?? '',
          );
        });
      });
    } else {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn || isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatar(),
                      const SizedBox(height: 20),
                      _buildEditableField('name', controllers['name']!),
                      _buildEditableField('email', controllers['email']!),
                      const SizedBox(height: 30),

                      _buildListTile(
                        icon: Icons.settings,
                        title: "Settings",
                        color: Colors.white70,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.logout,
                        title: "Logout",
                        color: Colors.red,
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ✅ Back button that always returns to NavScreen
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const NavScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = firebaseUser?.photoURL ?? currentUser?.avatar;

    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.amber,
      child: CircleAvatar(
        radius: 50,
        backgroundImage:
            (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
        onBackgroundImageError: (_, __) {
          // fallback silently if asset is missing
        },
      ),
    );
  }

  Widget _buildEditableField(String key, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          labelText: key.toUpperCase(),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
