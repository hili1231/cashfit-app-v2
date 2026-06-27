import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/nav_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class UpgradeToPremierScreen extends StatefulWidget {
  const UpgradeToPremierScreen({super.key});

  @override
  State<UpgradeToPremierScreen> createState() => _UpgradeToPremierScreenState();
}

class _UpgradeToPremierScreenState extends State<UpgradeToPremierScreen> {
  bool isUpgrading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navState = context.findAncestorStateOfType<NavScreenState>();
        if (navState != null) {
          navState.setDetailScreen(const LoginScreen());
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() => isUpgrading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.upgradeToPremium();
    if (!mounted) return;

    setState(() => isUpgrading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text("👑", style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                "VIP ACCESS UNLOCKED",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: Text(
            "Welcome to Premier! All Side Hustle cash contests, zero-ad experiences, and exclusive features are now unlocked for your account.",
            style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final navState = context.findAncestorStateOfType<NavScreenState>();
                if (navState != null) {
                  navState.setDetailScreen(null);
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text("EXPLORE PREMIER"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = userProvider.currentUser?.isPremiumActive() ?? false;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "PREMIER VIP",
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!mounted) return;
            final navState = context.findAncestorStateOfType<NavScreenState>();
            if (navState != null) {
              navState.setDetailScreen(null);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: colorScheme.primary,
                    size: 70,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "ELEVATE YOUR FITNESS JOURNEY",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Unlock Cashfit Premier",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // VIP FEATURES LIST
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCardDecoration(colorScheme),
                  child: Column(
                    children: [
                      _buildFeature(context, Icons.monetization_on, "Compete in Side Hustle Cash Contests"),
                      _buildFeature(context, Icons.block, "100% Ad-Free Experience"),
                      _buildFeature(context, Icons.star, "Exclusive Macro & Diet Customization"),
                      _buildFeature(context, Icons.support_agent, "24/7 VIP Fitness Coaching & Support"),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // PRICING CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary.withValues(alpha: 0.25), colorScheme.secondary.withValues(alpha: 0.25)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "30-DAY FREE TRIAL INCLUDED",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "£4.99 / month",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Cancel anytime in app settings",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isUpgrading || isPremium) ? null : _handleUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isPremium
                                ? "VIP MEMBERSHIP ACTIVE 👑"
                                : (isUpgrading ? "ACTIVATING VIP..." : "START 30-DAY FREE TRIAL"),
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
