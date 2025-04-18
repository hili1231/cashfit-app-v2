import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon), // Color is inherited from foregroundColor
        label: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold, // Optional: Add bold for emphasis
          ),
        ),
        style: theme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(colorScheme.primary),
          foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        ),
      ),
    );
  }
}
