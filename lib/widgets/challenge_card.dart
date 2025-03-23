import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';
import '../theme.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensures ripple effect works correctly
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.gold.withOpacity(
          0.2,
        ), // Softer gold ripple effect
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black, // Card background: black
            borderRadius: BorderRadius.circular(12),
            // Removed the boxShadow property to remove the glow
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge Title
                Text(
                  challenge.name,
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Challenge Description
                Text(
                  challenge.description,
                  style: GoogleFonts.oswald(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Participants & Arrow Icon
                Row(
                  children: [
                    Icon(Icons.people, color: AppTheme.gold, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      "${challenge.participants} Participants",
                      style: GoogleFonts.oswald(fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
