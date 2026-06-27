import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class WaterTrackerWidget extends StatefulWidget {
  const WaterTrackerWidget({super.key});

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget> {
  int currentMl = 0;
  final int targetMl = 2500;
  static const String _keyWaterDate = 'cashfit_water_date';
  static const String _keyWaterMl = 'cashfit_water_ml';

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyWaterDate);

    if (savedDate != todayStr) {
      await prefs.setString(_keyWaterDate, todayStr);
      await prefs.setInt(_keyWaterMl, 0);
      if (mounted) setState(() => currentMl = 0);
    } else {
      if (mounted) setState(() => currentMl = prefs.getInt(_keyWaterMl) ?? 0);
    }
  }

  Future<void> _addWater(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newAmount = (currentMl + amount).clamp(0, 5000);
    await prefs.setInt(_keyWaterMl, newAmount);
    if (mounted) setState(() => currentMl = newAmount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (currentMl / targetMl).clamp(0.0, 1.0);

    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: AppTheme.glassCardDecoration(colorScheme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DAILY HYDRATION TRACKER",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          "$currentMl / $targetMl ml",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _addWater(250),
                      icon: const Text("+250", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: () => _addWater(500),
                      icon: const Text("+500", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
