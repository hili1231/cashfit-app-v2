import '../../auth/login_screen.dart';
import '../../data/user_data.dart';
import '../../screens/upgrade_to_premium_screen.dart';
import 'package:flutter/material.dart';
import '../../data/side_hustle_data.dart';
import '../../models/side_hustle.dart';
import '../nav_screen.dart';
import 'side_hustle_detail_screen.dart';
import '../../theme.dart';

class SideHustleScreen extends StatelessWidget {
  const SideHustleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "SIDE HUSTLES",
                    style: AppTheme.headline.copyWith(
                      fontSize: 22,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              // List of Hustles
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sideHustleData.length,
                  itemBuilder: (context, index) {
                    final hustle = sideHustleData[index];
                    return _buildHustleCard(context, hustle);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHustleCard(BuildContext context, SideHustle hustle) {
    final navState = context.findAncestorStateOfType<NavScreenState>();
    final user = firebaseUser;

    // Calculate participants/spots left
    final totalParticipants = hustle.participants.length;
    final maxP = hustle.maxParticipants ?? 0;
    final spotsLeft = maxP > 0 ? (maxP - totalParticipants) : 0;

    return InkWell(
      onTap: () {
        // If not logged in => go to login
        if (user == null) {
          navState?.setDetailScreen(const LoginScreen());
          return;
        }

        // If logged in but not premium => upgrade screen
        if (currentUser?.isPremium != true) {
          navState?.setDetailScreen(const UpgradeToPremierScreen());
          return;
        }

        // If premium => side hustle detail
        navState?.setDetailScreen(SideHustleDetailScreen(hustle: hustle));
      },
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 3,
        shadowColor: Colors.black87,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hustle Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              // If your sideHustleData thumbnails are local asset paths,
              // you might want to use Image.asset, else Image.network:
              child: Image.asset(
                hustle.thumbnail,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
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
                    style: AppTheme.headline.copyWith(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    hustle.description,
                    style: AppTheme.smallText.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Spots left or participants
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.amber, size: 16),
                      const SizedBox(width: 5),
                      if (maxP > 0)
                        Text(
                          "$spotsLeft spots left",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        )
                      else
                        Text(
                          "$spotsLeft spots left",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Prize row + arrow
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "\$${hustle.reward} prize",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.business_center, size: 60, color: Colors.amber),
    );
  }
}
