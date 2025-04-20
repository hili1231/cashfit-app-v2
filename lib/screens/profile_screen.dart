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
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _weeklyReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;
  File? _selectedImage;

  final List<_Badge> _possibleBadges = [
    _Badge(
      name: "Profile Builder",
      earnedImagePath: "assets/images/badge_profile_builder.png",
      unearnedImagePath: "assets/images/badge_profile_builder_unearned.png",
    ),
    _Badge(
      name: "Plan Creator",
      earnedImagePath: "assets/images/badge_plan_creator.png",
      unearnedImagePath: "assets/images/badge_plan_creator_unearned.png",
    ),
    _Badge(
      name: "Weight Tracker",
      earnedImagePath: "assets/images/badge_weight_tracker.png",
      unearnedImagePath: "assets/images/badge_weight_tracker_unearned.png",
    ),
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      controllers['name'] = TextEditingController(
        text: userProvider.currentUser!.name,
      );
      controllers['email'] = TextEditingController(
        text: userProvider.currentUser!.email,
      );
      controllers['gender'] = TextEditingController(
        text: userProvider.currentUser!.gender,
      );
      controllers['age'] = TextEditingController(
        text: userProvider.currentUser!.age,
      );
      controllers['height'] = TextEditingController(
        text: userProvider.currentUser!.height,
      );
      controllers['weight'] = TextEditingController(
        text: userProvider.currentUser!.weight,
      );
      _notificationsEnabled = userProvider.currentUser!.notificationsEnabled;
      if (userProvider.currentUser!.dailyReminderTime != null) {
        final parts = userProvider.currentUser!.dailyReminderTime!.split(':');
        _dailyReminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (userProvider.currentUser!.weeklyReminderTime != null) {
        final parts = userProvider.currentUser!.weeklyReminderTime!.split(':');
        _weeklyReminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
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

    try {
      await userProvider.updateProfileFields(
        gender: controllers['gender']!.text,
        age: controllers['age']!.text,
        height: controllers['height']!.text,
        weight: controllers['weight']!.text,
        avatar: userProvider.currentUser!.avatar,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.primary,
          content: Text(
            userProvider.currentUser!.completedOneOffIds.contains(
                  'build_profile',
                )
                ? "Profile updated successfully"
                : "Profile updated! +15 points earned",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
        } else {
          _weeklyReminderTime = picked;
        }
      });
    }
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      await AuthService.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        AppTheme.createPageRoute(const NavScreen()),
        (route) => false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.primary,
            content: Text(
              "Logged out successfully",
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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

    const List<String> defaultAvatars = [
      'assets/images/default_avatar_1.png',
      'assets/images/default_avatar_2.png',
      'assets/images/default_avatar_3.png',
    ];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
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
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadCustomAvatar() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    try {
      await userProvider.uploadCustomAvatar(_selectedImage!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.primary,
            content: Text(
              "Avatar uploaded successfully",
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              "Failed to upload avatar: $e",
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(height: 20),
                _buildEditableField(
                  context,
                  'Name',
                  controllers['name']!,
                  readOnly: true,
                ),
                _buildEditableField(
                  context,
                  'Email',
                  controllers['email']!,
                  readOnly: true,
                ),
                _buildEditableField(context, 'Gender', controllers['gender']!),
                _buildEditableField(context, 'Age', controllers['age']!),
                _buildEditableField(context, 'Height', controllers['height']!),
                _buildEditableField(context, 'Weight', controllers['weight']!),
                const SizedBox(height: 10),
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
                    ),
                    onPressed: _isSaving ? null : _saveProfileFields,
                    child:
                        _isSaving
                            ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                            : const Text("Save Profile"),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: Icon(
                                  Icons.monetization_on,
                                  color: colorScheme.primary,
                                  size: 32,
                                ),
                                title: Text(
                                  "Points",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${userProvider.currentUser!.points ?? 0}",
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    AppTheme.createPageRoute(
                                      const PointsConversionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                leading: Icon(
                                  Icons.local_fire_department,
                                  color: colorScheme.primary,
                                  size: 32,
                                ),
                                title: Text(
                                  "Streak",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${userProvider.currentUser!.streak ?? 0} days",
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                "Balance: \$${userProvider.currentUser!.balance?.toStringAsFixed(2) ?? '0.00'}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: ElevatedButton(
                                style: theme.elevatedButtonTheme.style
                                    ?.copyWith(
                                      backgroundColor: WidgetStateProperty.all(
                                        colorScheme.primary,
                                      ),
                                      foregroundColor: WidgetStateProperty.all(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    AppTheme.createPageRoute(
                                      const PointsConversionScreen(),
                                    ),
                                  );
                                },
                                child: const Text("Points to Cash"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Badges",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio: 1.0,
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
                                const SizedBox(height: 4),
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
                const SizedBox(height: 10),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceContainer,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        const SizedBox(height: 8),
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
                              _dailyReminderTime.format(context),
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
                              _weeklyReminderTime.format(context),
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
                        const SizedBox(height: 8),
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
                            ),
                            onPressed:
                                _isSaving ? null : _saveNotificationPreferences,
                            child:
                                _isSaving
                                    ? CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                    )
                                    : const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildListTile(
                  icon: Icons.settings,
                  title: "Settings",
                  color: colorScheme.onSurface,
                  onTap: () {
                    Navigator.push(
                      context,
                      AppTheme.createPageRoute(const SettingsScreen()),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: colorScheme.error,
                  onTap: _handleLogout,
                ),
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

    final imageUrl = userProvider.currentUser?.avatar;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: colorScheme.primary,
          child: CircleAvatar(
            radius: 50,
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
        const SizedBox(width: 16),
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
