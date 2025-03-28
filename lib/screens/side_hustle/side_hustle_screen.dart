import 'package:cashfit/auth/login_screen.dart';
import 'package:cashfit/data/user_data.dart';
import 'package:cashfit/screens/upgrade_to_premium_screen.dart';
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
              // 🏷 Section Title
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

              // 💼 Hustle List
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

  /// 📌 Hustle Card Widget
  Widget _buildHustleCard(BuildContext context, SideHustle hustle) {
    return InkWell(
      onTap: () {
        final navState = context.findAncestorStateOfType<NavScreenState>();

        if (firebaseUser == null) {
          navState?.setDetailScreen(const LoginScreen());
        } else if (currentUser?.isPremium == true) {
          navState?.setDetailScreen(SideHustleDetailScreen(hustle: hustle));
        } else {
          navState?.setDetailScreen(const UpgradeToPremierScreen());
        }
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
            // 🖼 Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
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
                  // 🧾 Title
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

                  // 📝 Description
                  Text(
                    hustle.description,
                    style: AppTheme.smallText.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 💰 Reward & Navigation
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Prize: \$${hustle.reward}",
                        style: TextStyle(
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

  /// 🧩 Placeholder Image
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
