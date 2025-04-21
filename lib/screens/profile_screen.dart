import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import './settings_screen.dart';
import 'rewards/points_conversion_screen.dart';
import 'nav_screen.dart';
import '../theme.dart';

class _Badge {
  final String name;
  final String earnedImagePath;
  final String unearnedImagePath;

  _Badge({
    required this.name,
    required this.earnedImagePath,
    required this.unearnedImagePath,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, TextEditingController> controllers = {};
  bool _notificationsEnabled = true;
  bool _fieldsInitialized = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _weeklyReminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _dailyReminderTimeFormatted = "8:00 AM";
  String _weeklyReminderTimeFormatted = "9:00 AM";
  bool _isSaving = false;
  File? _selectedImage;
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedHeight;
  String? _selectedWeight;

  final List<_Badge> _possibleBadges = [
    _Badge(
      name: "Beginner",
      earnedImagePath: "assets/images/badge_beginner.png",
      unearnedImagePath: "assets/images/badge_beginner_unearned.png",
    ),
    _Badge(
      name: "Fitness Guru",
      earnedImagePath: "assets/images/badge_fitness_guru.png",
      unearnedImagePath: "assets/images/badge_fitness_guru_unearned.png",
    ),
    _Badge(
      name: "Streak King",
      earnedImagePath: "assets/images/badge_streak_king.png",
      unearnedImagePath: "assets/images/badge_streak_king_unearned.png",
    ),
    _Badge(
      name: "Nutrition Pro",
      earnedImagePath: "assets/images/badge_nutrition_pro.png",
      unearnedImagePath: "assets/images/badge_nutrition_pro_unearned.png",
    ),
  ];

  final List<String> _genderOptions = [
    "Male",
    "Female",
    "Non-Binary",
    "Other",
    "Prefer not to say",
  ];
  final List<String> _ageOptions = List.generate(
    83,
    (index) => (18 + index).toString(),
  );
  final List<String> _heightOptions = List.generate(
    101,
    (index) => (120 + index).toString(),
  );
  final List<String> _weightOptions = List.generate(
    171,
    (index) => (30 + index).toString(),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fieldsInitialized) {
      _initializeFields();
      Provider.of<UserProvider>(context, listen: false).updateStreak();
      _fieldsInitialized = true;
    }
  }

  void _initializeFields() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      controllers['name'] = TextEditingController(
        text: userProvider.currentUser!.name,
      );
      controllers['email'] = TextEditingController(
        text: userProvider.currentUser!.email,
      );
      _selectedGender =
          userProvider.currentUser!.gender.isNotEmpty
              ? userProvider.currentUser!.gender
              : null;
      _selectedAge =
          userProvider.currentUser!.age.isNotEmpty
              ? userProvider.currentUser!.age
              : null;
      _selectedHeight =
          userProvider.currentUser!.height.isNotEmpty
              ? userProvider.currentUser!.height
              : null;
      _selectedWeight =
          userProvider.currentUser!.weight.isNotEmpty
              ? userProvider.currentUser!.weight
              : null;
      _notificationsEnabled = userProvider.currentUser!.notificationsEnabled;
      if (userProvider.currentUser!.dailyReminderTime != null) {
        final parts = userProvider.currentUser!.dailyReminderTime!.split(':');
        _dailyReminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        _dailyReminderTimeFormatted = _dailyReminderTime.format(context);
      }
      if (userProvider.currentUser!.weeklyReminderTime != null) {
        final parts = userProvider.currentUser!.weeklyReminderTime!.split(':');
        _weeklyReminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        _weeklyReminderTimeFormatted = _weeklyReminderTime.format(context);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfileFields() async {
    setState(() {
      _isSaving = true;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Update weight separately to ensure weightHistory and lastWeightUpdateDate are updated
      if (_selectedWeight != null &&
          _selectedWeight != userProvider.currentUser!.weight) {
        await userProvider.updateWeight(_selectedWeight!);
      }

      // Update other profile fields
      await userProvider.updateProfileFields(
        name: controllers['name']!.text,
        gender: _selectedGender ?? '',
        age: _selectedAge ?? '',
        height: _selectedHeight ?? '',
        weight: _selectedWeight ?? '',
        avatar: userProvider.currentUser!.avatar,
      );

      // Claim reward for building profile if not already claimed and profile is complete
      if (!userProvider.currentUser!.completedOneOffIds.contains(
            'build_profile',
          ) &&
          controllers['name']!.text.isNotEmpty &&
          _selectedGender != null &&
          _selectedAge != null &&
          _selectedHeight != null &&
          _selectedWeight != null &&
          userProvider.currentUser!.avatar.isNotEmpty) {
        await userProvider.claimReward(
          'build_profile',
          15,
          badge: 'Profile Builder',
        );
      }

      // Refresh user data to ensure EarnPointsScreen sees updated state
      await userProvider.refreshUser();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Profile updated successfully",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to update profile: $e",
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
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() {
      _isSaving = true;
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        await AuthService.instance
            .updateUserFields(userProvider.currentUser!.id, {
              'notificationsEnabled': _notificationsEnabled,
              'dailyReminderTime':
                  "${_dailyReminderTime.hour}:${_dailyReminderTime.minute}",
              'weeklyReminderTime':
                  "${_weeklyReminderTime.hour}:${_weeklyReminderTime.minute}",
            });
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Notification preferences saved successfully",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to save preferences: $e",
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
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDaily) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDaily ? _dailyReminderTime : _weeklyReminderTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDaily) {
          _dailyReminderTime = picked;
          _dailyReminderTimeFormatted = picked.format(context);
        } else {
          _weeklyReminderTime = picked;
          _weeklyReminderTimeFormatted = picked.format(context);
        }
      });
    }
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Store ScaffoldMessengerState and NavigatorState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await AuthService.instance.signOut();

      navigator.pushAndRemoveUntil(
        AppTheme.createPageRoute(const NavScreen()),
        (route) => false,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Logged out successfully",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to log out: $e",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _selectDefaultAvatar(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    const List<String> defaultAvatars = [
      'assets/images/default_avatar_1.png',
      'assets/images/default_avatar_2.png',
      'assets/images/default_avatar_3.png',
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        // Store NavigatorState for the dialog context
        final dialogNavigator = Navigator.of(dialogContext);
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            "Select Default Avatar",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Text(
                        "Current Avatar",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primary,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: colorScheme.surface,
                          backgroundImage:
                              (userProvider.currentUser?.avatar != null &&
                                      userProvider
                                          .currentUser!
                                          .avatar
                                          .isNotEmpty)
                                  ? (userProvider.currentUser!.avatar
                                          .startsWith('http')
                                      ? NetworkImage(
                                        userProvider.currentUser!.avatar,
                                      )
                                      : AssetImage(
                                        userProvider.currentUser!.avatar,
                                      ))
                                  : const AssetImage(
                                    'assets/images/default_avatar_1.png',
                                  ),
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                    ],
                  ),
                ),
                ...defaultAvatars.map((avatarPath) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(avatarPath),
                    ),
                    title: Text(
                      avatarPath.split('/').last.replaceFirst('.png', ''),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () async {
                      try {
                        await userProvider.updateAvatar(avatarPath);
                        dialogNavigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            backgroundColor: colorScheme.primary,
                            content: Text(
                              "Avatar updated successfully",
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
                              "Failed to update avatar: $e",
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
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogNavigator.pop(),
              child: Text(
                "Cancel",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadCustomAvatar() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Store ScaffoldMessengerState before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    try {
      await userProvider.uploadCustomAvatar(_selectedImage!);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            "Avatar uploaded successfully",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.error,
          content: Text(
            "Failed to upload avatar: $e",
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
          _selectedImage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final verticalPadding = screenSize.height * 0.015;
    final horizontalPadding = screenSize.width * 0.05;
    final sectionSpacing = screenSize.height * 0.02;

    if (userProvider.isLoading) {
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

    if (userProvider.errorMessage != null) {
      return Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              userProvider.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      );
    }

    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      return const LoginScreen();
    }

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                SizedBox(height: sectionSpacing),
                _buildEditableField(context, 'Name', controllers['name']!),
                _buildEditableField(
                  context,
                  'Email',
                  controllers['email']!,
                  readOnly: true,
                ),
                _buildDropdownField(
                  context,
                  'Gender',
                  _selectedGender,
                  _genderOptions,
                  (value) => setState(() => _selectedGender = value),
                ),
                _buildDropdownField(
                  context,
                  'Age (years)',
                  _selectedAge,
                  _ageOptions,
                  (value) => setState(() => _selectedAge = value),
                ),
                _buildDropdownField(
                  context,
                  'Height (cm)',
                  _selectedHeight,
                  _heightOptions,
                  (value) => setState(() => _selectedHeight = value),
                ),
                _buildDropdownField(
                  context,
                  'Weight (kg)',
                  _selectedWeight,
                  _weightOptions,
                  (value) => setState(() => _selectedWeight = value),
                ),
                SizedBox(height: verticalPadding),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        colorScheme.onPrimary,
                      ),
                      padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(
                          horizontal: horizontalPadding * 0.5,
                          vertical: verticalPadding * 0.5,
                        ),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveProfileFields,
                    child:
                        _isSaving
                            ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                            : Text(
                              "Save Profile",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: sectionSpacing),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  margin: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: Padding(
                    padding: EdgeInsets.all(
                      horizontalPadding * 0.8,
                    ), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Achievements",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ), // Reduced padding
                                leading: Image.asset(
                                  'assets/images/fitcoin_icon.png',
                                  width: 24, // Reduced icon size
                                  height: 24,
                                ),
                                title: Text(
                                  "FitCoins",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${userProvider.currentUser!.points ?? 0}",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  context
                                      .findAncestorStateOfType<NavScreenState>()
                                      ?.setDetailScreen(
                                        const PointsConversionScreen(),
                                      );
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ), // Reduced padding
                                leading: Icon(
                                  Icons.local_fire_department,
                                  color: colorScheme.primary,
                                  size: 24, // Reduced icon size
                                ),
                                title: Text(
                                  "Streak",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${userProvider.currentUser!.checkInStreak} days",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding * 0.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: horizontalPadding),
                              child: Text(
                                "Balance: \$${userProvider.currentUser!.balance?.toStringAsFixed(2) ?? '0.00'}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                right: horizontalPadding,
                              ),
                              child: ElevatedButton(
                                style: theme.elevatedButtonTheme.style
                                    ?.copyWith(
                                      backgroundColor: WidgetStateProperty.all(
                                        colorScheme.primary,
                                      ),
                                      foregroundColor: WidgetStateProperty.all(
                                        colorScheme.onPrimary,
                                      ),
                                      padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(
                                          horizontal: horizontalPadding * 0.5,
                                          vertical: verticalPadding * 0.5,
                                        ),
                                      ),
                                    ),
                                onPressed: () {
                                  context
                                      .findAncestorStateOfType<NavScreenState>()
                                      ?.setDetailScreen(
                                        const PointsConversionScreen(),
                                      );
                                },
                                child: Text(
                                  "FitCoins to Cash",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalPadding),
                        Text(
                          "Badges",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenSize.width < 360 ? 3 : 4,
                                crossAxisSpacing: horizontalPadding * 0.5,
                                mainAxisSpacing: verticalPadding * 0.5,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _possibleBadges.length,
                          itemBuilder: (context, index) {
                            final badge = _possibleBadges[index];
                            final userBadges =
                                userProvider.currentUser!.badges ?? [];
                            final hasBadge = userBadges.contains(badge.name);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          hasBadge
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      hasBadge
                                          ? badge.earnedImagePath
                                          : badge.unearnedImagePath,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: verticalPadding * 0.5),
                                Text(
                                  badge.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        hasBadge
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sectionSpacing),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  margin: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notification Settings",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          child: SwitchListTile(
                            title: Text(
                              "Enable Notifications",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            activeColor: colorScheme.primary,
                          ),
                        ),
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          child: ListTile(
                            title: Text(
                              "Daily Check-In Reminder",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _dailyReminderTimeFormatted,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            onTap: () => _selectTime(context, true),
                          ),
                        ),
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          child: ListTile(
                            title: Text(
                              "Weekly Photo Update Reminder",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _weeklyReminderTimeFormatted,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                colorScheme.primary,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                colorScheme.onPrimary,
                              ),
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                  horizontal: horizontalPadding * 0.5,
                                  vertical: verticalPadding * 0.5,
                                ),
                              ),
                            ),
                            onPressed:
                                _isSaving ? null : _saveNotificationPreferences,
                            child:
                                _isSaving
                                    ? CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                    )
                                    : Text(
                                      "Save",
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                          ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sectionSpacing),
                _buildListTile(
                  icon: Icons.settings,
                  title: "Settings",
                  color: colorScheme.onSurface,
                  onTap: () {
                    context
                        .findAncestorStateOfType<NavScreenState>()
                        ?.setDetailScreen(const SettingsScreen());
                  },
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: colorScheme.error,
                  onTap: _handleLogout,
                ),
                SizedBox(height: verticalPadding * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final buttonPadding = screenSize.width * 0.03;

    final imageUrl = userProvider.currentUser?.avatar;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: screenSize.width * 0.15,
          backgroundColor: colorScheme.primary,
          child: CircleAvatar(
            radius: screenSize.width * 0.135,
            backgroundColor: colorScheme.surface,
            backgroundImage:
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? (imageUrl.startsWith('http')
                        ? NetworkImage(imageUrl)
                        : AssetImage(imageUrl))
                    : const AssetImage('assets/images/default_avatar_1.png'),
            onBackgroundImageError: (exception, stackTrace) {},
          ),
        ),
        SizedBox(width: screenSize.width * 0.04),
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: Size(0, screenSize.height * 0.045),
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                  vertical: buttonPadding * 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _selectDefaultAvatar(context),
              child: Text(
                "Change Avatar",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            SizedBox(height: buttonPadding),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: Size(0, screenSize.height * 0.045),
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding,
                  vertical: buttonPadding * 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _uploadCustomAvatar,
              child: Text(
                "Upload Avatar",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final verticalPadding = screenSize.height * 0.015;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding * 0.5),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
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

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final verticalPadding = screenSize.height * 0.015;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding * 0.5),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
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
        items:
            options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        hint: Text(
          "Select $label",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final verticalPadding = screenSize.height * 0.015;

    return Card(
      color: colorScheme.surfaceContainer,
      margin: EdgeInsets.symmetric(vertical: verticalPadding * 0.5),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(color: color),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
