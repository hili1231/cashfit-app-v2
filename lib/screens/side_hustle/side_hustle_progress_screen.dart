import 'package:flutter/material.dart';
import '../../models/side_hustle.dart';

class SideHustleProgressScreen extends StatelessWidget {
  final SideHustle hustle;

  const SideHustleProgressScreen({super.key, required this.hustle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hustle.title), backgroundColor: Colors.black),
      body: Center(
        child: Text(
          'Upload your progress videos for "${hustle.title}"',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
