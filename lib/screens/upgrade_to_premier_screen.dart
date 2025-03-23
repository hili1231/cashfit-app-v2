import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpgradeToPremierScreen extends StatelessWidget {
  const UpgradeToPremierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Go Premier"),
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Unlock the Full Experience",
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildFeature("No Ads"),
            _buildFeature("Access to Premium Challenges"),
            _buildFeature("Eligible for Side Hustle Earnings"),
            _buildFeature("Priority Support"),
            _buildFeature("Early Access to New Features"),
            const SizedBox(height: 30),
            _buildPricingCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            "Premier Membership",
            style: GoogleFonts.oswald(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Just £4.99 / month",
            style: const TextStyle(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Hook up your billing / auth logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Upgrade functionality coming soon!"),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
            child: const Text("Upgrade Now"),
          ),
        ],
      ),
    );
  }
}
