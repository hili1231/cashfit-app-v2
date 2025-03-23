import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/side_hustle.dart';
import '../screens/side_hustle_detail_screen.dart';

class SideHustleCard extends StatelessWidget {
  final SideHustle hustle;

  const SideHustleCard({super.key, required this.hustle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Ensures ripple effect works correctly
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SideHustleDetailScreen(hustle: hustle),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24, // Soft ripple effect
        child: Card(
          color: Colors.black, // Black background to match workout cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          // Subtle white glow
          shadowColor: Colors.white70.withAlpha(25),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Side Hustle Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildHustleImage(),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  hustle.title,
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Description (Truncated)
                Text(
                  hustle.description,
                  style: GoogleFonts.oswald(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Reward Info & "Start Now" Button
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "\$${hustle.reward} Prize",
                      style: GoogleFonts.oswald(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SideHustleDetailScreen(hustle: hustle),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 20,
                      ),
                      label: Text(
                        "Start Now",
                        style: GoogleFonts.oswald(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, // Gold button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Hustle Image with error handling.
  Widget _buildHustleImage() {
    return Image.asset(
      hustle.thumbnail,
      fit: BoxFit.cover,
      height: 150,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
    );
  }

  /// Placeholder image if no image is available.
  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.business_center, size: 40, color: Colors.grey),
    );
  }
}
