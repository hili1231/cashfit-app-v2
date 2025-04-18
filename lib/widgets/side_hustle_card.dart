import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/side_hustle.dart';
import '../screens/side_hustle/side_hustle_detail_screen.dart';
import '../theme.dart';

class SideHustleCard extends StatelessWidget {
  final SideHustle hustle;

  const SideHustleCard({super.key, required this.hustle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedCard(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 160,
        height: 220,
        child: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SideHustleDetailScreen(hustle: hustle),
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
                child: _buildHustleImage(context),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  hustle.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "\$${hustle.reward} prize",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: FilledButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SideHustleDetailScreen(hustle: hustle),
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
                    "View Hustle",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildHustleImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = hustle.thumbnail.trim();

    if (imageUrl.isEmpty) {
      return Container(
        height: 90,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(
          Icons.business_center,
          size: 40,
          color: colorScheme.primary,
        ),
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
              Icons.business_center,
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
              Icons.business_center,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
      memCacheWidth: 320,
      maxWidthDiskCache: 320,
    );
  }
}
