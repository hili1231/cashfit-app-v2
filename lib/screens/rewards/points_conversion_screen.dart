import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../nav_screen.dart'; // Import NavScreen to access NavScreenState

class PointsConversionScreen extends StatefulWidget {
  const PointsConversionScreen({super.key});

  @override
  State<PointsConversionScreen> createState() => _PointsConversionScreenState();
}

class _PointsConversionScreenState extends State<PointsConversionScreen> {
  final TextEditingController _pointsController = TextEditingController();
  final double conversionRate = 0.0002; // 5000 points = $1 (0.0002 per point)
  final int minimumConversionThreshold = 5000; // Minimum points to convert
  double cashValue = 0.0;
  bool isLoading = false;
  bool isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
    _pointsController.addListener(_calculateCashValue);
  }

  void _checkUserLogin() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  void _calculateCashValue() {
    final points = int.tryParse(_pointsController.text) ?? 0;
    setState(() {
      cashValue = points * conversionRate;
    });
  }

  Future<void> _convertPoints() async {
    setState(() {
      isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pointsToConvert = int.tryParse(_pointsController.text) ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      if (pointsToConvert <= 0) {
        throw Exception("Please enter a valid number of points");
      }

      if (pointsToConvert < minimumConversionThreshold) {
        throw Exception(
          "You must convert at least $minimumConversionThreshold points",
        );
      }

      if (pointsToConvert > (userProvider.currentUser!.points ?? 0)) {
        throw Exception("You don't have enough points");
      }

      // Update points and balance in Firestore
      await AuthService.instance
          .updateUserFields(userProvider.currentUser!.id, {
            'points': FieldValue.increment(-pointsToConvert),
            'balance': FieldValue.increment(cashValue),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Converted $pointsToConvert points to \$${cashValue.toStringAsFixed(2)}!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Clear the input field after conversion
      _pointsController.clear();
      // Update cash value to reflect the cleared input
      setState(() {
        cashValue = 0.0;
      });

      // Refresh user data in the background to ensure consistency
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserData(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to convert points: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _withdrawBalance() async {
    setState(() {
      isWithdrawing = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      final currentBalance = userProvider.currentUser!.balance ?? 0.0;
      if (currentBalance <= 0) {
        throw Exception("No balance available to withdraw");
      }

      // Simulate withdrawal by resetting balance to 0
      // In a real implementation, this would integrate with a payment system
      await AuthService.instance.updateUserFields(
        userProvider.currentUser!.id,
        {'balance': 0.0},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Successfully withdrew \$${currentBalance.toStringAsFixed(2)}!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Refresh user data in the background to ensure consistency
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUserData(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to withdraw balance: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isWithdrawing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (userProvider.isLoading ||
        !userProvider.isLoggedIn ||
        userProvider.currentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Convert Points to Cash",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // Use NavScreenState to clear the detail screen
                        final navState =
                            context.findAncestorStateOfType<NavScreenState>();
                        if (navState != null) {
                          navState.clearDetailScreen();
                        } else {
                          Navigator.pop(
                            context,
                          ); // Fallback in case NavScreenState isn't found
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Main Content in Card
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Available Points: ${userProvider.currentUser!.points ?? 0}",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Conversion Rate: 5000 points = \$1",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: "Points to Convert",
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Cash Value: \$${cashValue.toStringAsFixed(2)}",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              colorScheme.primary,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              colorScheme.onPrimary,
                            ),
                            minimumSize: WidgetStateProperty.all(
                              const Size(double.infinity, 50),
                            ),
                          ),
                          onPressed: isLoading ? null : _convertPoints,
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                  )
                                  : const Text("Convert to Cash"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Balance: \$${userProvider.currentUser!.balance?.toStringAsFixed(2)}",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              colorScheme.primary,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              colorScheme.onPrimary,
                            ),
                            minimumSize: WidgetStateProperty.all(
                              const Size(double.infinity, 50),
                            ),
                          ),
                          onPressed: isWithdrawing ? null : _withdrawBalance,
                          child:
                              isWithdrawing
                                  ? CircularProgressIndicator(
                                    color: colorScheme.onPrimary,
                                  )
                                  : const Text("Withdraw Balance"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
