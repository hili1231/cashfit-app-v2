import 'package:flutter/material.dart';
import '../theme.dart'; // ✅ Import theme

class SelectionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const SelectionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black), // ✅ Icon in button
        label: Text(
          text,
          style: AppTheme.headline.copyWith(color: Colors.black, fontSize: 16),
        ),
        style: AppTheme.buttonStyle, // ✅ Use centralized button style
      ),
    );
  }
}
