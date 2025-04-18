import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../models/challenge.dart';
import '../../models/app_user.dart';
import '../../ad_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart'; // Add this import for AppTheme

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;
  final String currentUserId;

  const ChallengeProgressScreen({
    super.key,
    required this.challenge,
    required this.currentUserId,
  });

  @override
  ChallengeProgressScreenState createState() => ChallengeProgressScreenState();
}

class ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _weightController = TextEditingController();
  bool isUpdating = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData(widget.currentUserId);
    if (!mounted) return; // Guard context usage
    setState(() {});
  }

  Future<void> _submitWeeklyPhoto(AppUser user) async {
    final double? weight = double.tryParse(_weightController.text);
    if (weight == null) {
      setState(() {
        errorMessage = 'Please enter a valid weight';
      });
      return;
    }

    setState(() {
      isUpdating = true;
      errorMessage = '';
    });

    // Store ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        if (!mounted) return; // Guard context usage
        setState(() {
          errorMessage = 'Photo is required for weekly check-in';
        });
        return;
      }

      await _authService.submitWeeklyPhoto(user.id, weight, image);
      if (!mounted) return; // Guard context usage
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("Weekly photo submitted successfully!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _weightController.clear();
    } catch (e) {
      if (!mounted) return; // Guard context usage
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return; // Guard context usage
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final AppUser? user = userProvider.currentUser;

    if (user == null) {
      return Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    final weeklyCheckIns =
        user.challengeCheckIns
            .where((checkIn) => checkIn['type'] == 'weekly')
            .length;

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Your Challenge Progress",
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 2,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challenge.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Progress: ${user.challengeProgress}%",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              LinearProgressIndicator(
                value: user.challengeProgress / 100,
                backgroundColor: colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                "Initial Weight: ${widget.challenge.initialWeight} kg",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "Target Weight: ${widget.challenge.targetWeight} kg",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "Weekly Check-Ins: $weeklyCheckIns/${(widget.challenge.durationDays / 7).ceil()}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Weekly Photo Update:",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: "Current Weight (kg)",
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
                onPressed: isUpdating ? null : () => _submitWeeklyPhoto(user),
                child:
                    isUpdating
                        ? CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                        )
                        : Text(
                          "Submit Weekly Photo",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
              ),
              const SizedBox(height: 20),
              AdHelper.nativeAdWidget(context),
            ],
          ),
        ),
        bottomNavigationBar: AdHelper.bannerAdWidget(context),
      ),
    );
  }
}
