import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/login_screen.dart';
import '../../screens/upgrade_to_premium_screen.dart';
import '../../models/side_hustle.dart';
import '../nav_screen.dart';
import 'side_hustle_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class SideHustleScreen extends StatelessWidget {
  const SideHustleScreen({super.key});

  Future<List<SideHustle>> _fetchSideHustles() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('sideHustles').get();
      final list = snapshot.docs
          .map((doc) => SideHustle.fromMap(doc.data()..['id'] = doc.id))
          .toList();
      if (list.isNotEmpty) return list;
      return _getSampleSideHustles();
    } catch (e) {
      return _getSampleSideHustles();
    }
  }

  List<SideHustle> _getSampleSideHustles() {
    return [
      SideHustle(
        id: 'hustle_1',
        title: 'Fitness Community Ambassador',
        description: 'Lead group workout discussions and earn weekly FitCoin bonuses.',
        reward: 150,
        videoRequirement: 'Record a 30s community workout update',
        thumbnail: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80',
        maxParticipants: 10,
        participants: ['user_1', 'user_2'],
      ),
      SideHustle(
        id: 'hustle_2',
        title: 'Healthy Recipe Creator',
        description: 'Submit verified weight loss recipes to earn rewards.',
        reward: 200,
        videoRequirement: 'Record a meal prep demonstration video',
        thumbnail: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80',
        maxParticipants: 15,
        participants: ['user_1'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: AppTheme.backgroundGradient(
        colorScheme,
      ), // Add gradient background
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  "SIDE HUSTLES", // Updated title to match other screens
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              // List of Hustles
              Expanded(
                child: FutureBuilder<List<SideHustle>>(
                  future: _fetchSideHustles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No side hustles found",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    final sideHustles = snapshot.data!;
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sideHustles.length,
                      itemBuilder: (context, index) {
                        final hustle = sideHustles[index];
                        return _buildHustleCard(
                          context,
                          theme,
                          colorScheme,
                          hustle,
                          user,
                          userProvider,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHustleCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    SideHustle hustle,
    User? user,
    UserProvider userProvider,
  ) {
    final navState = context.findAncestorStateOfType<NavScreenState>();

    // Calculate participants/spots left
    final totalParticipants = hustle.participants.length;
    final maxP = hustle.maxParticipants ?? 0;
    final spotsLeft = maxP > 0 ? (maxP - totalParticipants) : 0;

    return Card(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // If not logged in => go to login
          if (user == null) {
            navState?.setDetailScreen(const LoginScreen());
            return;
          }

          // If logged in but not premium => upgrade screen
          if (!userProvider.currentUser!.isPremiumActive()) {
            navState?.setDetailScreen(const UpgradeToPremierScreen());
            return;
          }

          // If premium => side hustle detail
          navState?.setDetailScreen(SideHustleDetailScreen(hustle: hustle));
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hustle Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: hustle.thumbnail.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: hustle.thumbnail,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholderImage(colorScheme),
                      errorWidget: (_, __, ___) => _buildPlaceholderImage(colorScheme),
                    )
                  : Image.asset(
                      hustle.thumbnail,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(colorScheme),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    hustle.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    hustle.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Spots left or participants
                  Row(
                    children: [
                      Icon(Icons.people, color: colorScheme.primary, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        maxP > 0
                            ? "$spotsLeft spots left"
                            : "$totalParticipants participants",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Prize row + arrow
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "\$${hustle.reward} prize",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Icon(
          Icons.business_center,
          size: 60,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
