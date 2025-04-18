import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/side_hustle.dart';
import '../nav_screen.dart';
import 'side_hustle_screen.dart';
import '../upgrade_to_premium_screen.dart';
import '../../auth/login_screen.dart';
import '../../providers/user_provider.dart';
import 'side_hustle_progress_screen.dart';

class SideHustleDetailScreen extends StatefulWidget {
  final SideHustle hustle;

  const SideHustleDetailScreen({super.key, required this.hustle});

  @override
  State<SideHustleDetailScreen> createState() => _SideHustleDetailScreenState();
}

class _SideHustleDetailScreenState extends State<SideHustleDetailScreen> {
  bool isJoining = false;
  bool hasJoined = false;
  bool isLoading = true;
  final Map<String, TextEditingController> controllers = {};
  User? firebaseCurrentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadUser();
  }

  Future<void> _checkAuthAndLoadUser() async {
    firebaseCurrentUser = FirebaseAuth.instance.currentUser;

    if (firebaseCurrentUser == null) {
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
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) {
      await userProvider.loadUserData(firebaseCurrentUser!.uid);
    }

    if (userProvider.currentUser != null) {
      controllers['name'] = TextEditingController(
        text: userProvider.currentUser!.name,
      );
      controllers['email'] = TextEditingController(
        text: userProvider.currentUser!.email,
      );
      hasJoined = userProvider.currentUser!.joinedSideHustles.contains(
        widget.hustle.id,
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _joinHustle() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.currentUser?.isPremiumActive() ?? false;
    if (!isPremium) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeToPremierScreen()),
        );
      }
      return;
    }

    setState(() => isJoining = true);
    final userId = userProvider.currentUser?.id;
    if (userId == null) return;

    try {
      if (!userProvider.currentUser!.joinedSideHustles.contains(
        widget.hustle.id,
      )) {
        userProvider.currentUser!.joinedSideHustles.add(widget.hustle.id);
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'joinedSideHustles': userProvider.currentUser!.joinedSideHustles},
        );
      }

      final hustleRef = FirebaseFirestore.instance
          .collection('sideHustles')
          .doc(widget.hustle.id);

      final updatedParticipants = List<String>.from(widget.hustle.participants);
      if (!updatedParticipants.contains(userId)) {
        updatedParticipants.add(userId);
      }

      await hustleRef.update({'participants': updatedParticipants});
      widget.hustle.participants.add(userId);

      setState(() => hasJoined = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              "Joined Side Hustle successfully!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
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
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              "Join failed: $e",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
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

    setState(() => isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    if (isLoading || firebaseCurrentUser == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    final isPremium = userProvider.currentUser?.isPremiumActive() ?? false;
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.hustle.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 2,
        ),
        backgroundColor: colorScheme.surface,
        body: Center(
          child: ElevatedButton(
            style: theme.elevatedButtonTheme.style?.copyWith(
              backgroundColor: WidgetStateProperty.all(colorScheme.primary),
              foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UpgradeToPremierScreen(),
                ),
              );
            },
            child: const Text("Upgrade to Premium to Join Side Hustle"),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        widget.hustle.thumbnail,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _buildPlaceholderImage(colorScheme),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hustle.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.hustle.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Prize: \$${widget.hustle.reward}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Video Requirement:",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.hustle.videoRequirement,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "${widget.hustle.participants.length} participants have joined",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                colorScheme.primary,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                colorScheme.onPrimary,
                              ),
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            onPressed:
                                isJoining
                                    ? null
                                    : () {
                                      if (hasJoined) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => SideHustleProgressScreen(
                                                  hustle: widget.hustle,
                                                ),
                                          ),
                                        );
                                      } else {
                                        _joinHustle();
                                      }
                                    },
                            icon:
                                isJoining
                                    ? const SizedBox.shrink()
                                    : Icon(
                                      Icons.videocam,
                                      color: colorScheme.onPrimary,
                                    ),
                            label:
                                isJoining
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      hasJoined
                                          ? "View Progress"
                                          : "Join Side Hustle",
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  final navState =
                      context.findAncestorStateOfType<NavScreenState>();
                  if (navState != null) {
                    navState.setDetailScreen(const SideHustleScreen());
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainer,
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
