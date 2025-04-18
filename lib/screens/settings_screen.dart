import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import './admin/admin_panel_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    // Check if the user is logged in using UserProvider synchronously
    _checkUserLogin();
  }

  void _checkUserLogin() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      // Navigate immediately without async gap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (userProvider.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (userProvider.errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            userProvider.errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      // This case is already handled in initState, but added for safety
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          "Settings",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Divider(color: colorScheme.outline),

          // Admin Panel (for admin users)
          if (userProvider.currentUser!.isAdmin)
            Card(
              elevation: 1,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings,
                  color: colorScheme.primary,
                ),
                title: Text(
                  "Admin Panel",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  );
                },
              ),
            ),

          if (userProvider.currentUser!.isAdmin)
            Divider(color: colorScheme.outline),

          // Logout
          Card(
            elevation: 1,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                "Logout",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              onTap: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }
}
