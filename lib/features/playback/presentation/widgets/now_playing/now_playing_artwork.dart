import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/audifi_network_image.dart';

/// Large album artwork card for the expanded Now Playing screen.
/// Matches `.big` in `references/UI/audifi.html`.
class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({super.key, required this.imageUrl, this.trackTitle});

  final String? imageUrl;
  final String? trackTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final sizeOf = MediaQuery.sizeOf(context);
    final screenWidth = sizeOf.width;
    final screenHeight = sizeOf.height;

    // Responsive scaling: up to 380px, but capped to avoid vertical overflow on short screens
    final maxAvailableWidth = screenWidth - 48.0;
    final maxAvailableHeight = screenHeight * 0.42;
    final size = min(
      maxAvailableWidth,
      min(maxAvailableHeight, 380.0),
    ).clamp(180.0, 380.0);

    return Semantics(
      label: trackTitle != null
          ? 'Album artwork for $trackTitle'
          : 'Now playing track artwork',
      image: true,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            color: colors.surface2,
            border: Border.all(
              color: colors.surface2.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 36.0,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.0),
            child: AudifiNetworkImage(
              imageUrl: imageUrl,
              width: size,
              height: size,
              borderRadius: 18.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
