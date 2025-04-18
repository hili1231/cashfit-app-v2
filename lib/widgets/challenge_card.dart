import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/challenge.dart';
import '../screens/challenges/challenge_detail_screen.dart';
import '../theme.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedCard(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 160,
        height: 240,
        child: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeDetailScreen(challenge: challenge),
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: _buildChallengeImage(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SizedBox(
                  height: 40,
                  child: Text(
                    challenge.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 20,
                  child: Text(
                    "${challenge.participants.length} participants",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    ChallengeDetailScreen(challenge: challenge),
                          ),
                        ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "View Challenge",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = challenge.image.trim();

    if (imageUrl.isEmpty) {
      return Container(
        height: 90,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.fitness_center, size: 40, color: colorScheme.primary),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 90,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder:
          (context, url) => Container(
            height: 90,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            height: 90,
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            alignment: Alignment.center,
            child: Icon(
              Icons.fitness_center,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
      memCacheWidth: 320,
      maxWidthDiskCache: 320,
    );
  }
}
