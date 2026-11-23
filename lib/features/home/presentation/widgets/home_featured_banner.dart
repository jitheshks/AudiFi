import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_network_image.dart';
import '../../../tracks/domain/entities/track.dart';

/// Featured top trending banner styled after `.feat` in `audifi.html`.
class HomeFeaturedBanner extends StatelessWidget {
  const HomeFeaturedBanner({
    super.key,
    required this.track,
    required this.onPlay,
  });

  final Track track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Semantics(
      button: true,
      label:
          'Play featured trending track: ${track.title} by ${track.user?.name ?? "Unknown artist"}',
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          height: 190.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: colors.surface1,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Artwork
              AudifiNetworkImage(
                imageUrl: track.artwork?.primaryUrl,
                borderRadius: BorderRadius.circular(20.0),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),

              // Track Metadata and Overlay Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUDIUS · TRENDING',
                      style: AppTypography.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    AppSpacing.vGap6,
                    Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    AppSpacing.vGap4,
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.user?.name ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        if (track.user?.isVerified ?? false) ...[
                          AppSpacing.hGap4,
                          Icon(
                            Icons.verified_rounded,
                            color: colors.accent,
                            size: 16.0,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
