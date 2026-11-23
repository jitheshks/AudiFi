import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../queue/queue_sheet.dart';

/// Top app bar for the expanded Now Playing screen matching `.top` in `references/UI/audifi.html`.
class NowPlayingAppBar extends StatelessWidget {
  const NowPlayingAppBar({
    super.key,
    this.contextHeader = 'Now Playing',
    this.onMoreTap,
  });

  final String contextHeader;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // Dismiss / collapse chevron down button
          SizedBox(
            width: 48.0,
            height: 48.0,
            child: IconButton(
              onPressed: () => context.pop(),
              tooltip: 'Minimize now playing screen',
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textPrimary,
                size: 32.0,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                contextHeader.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.micro.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // Queue sheet button
          SizedBox(
            width: 48.0,
            height: 48.0,
            child: IconButton(
              onPressed: () => QueueSheet.show(context),
              tooltip: 'Open playback queue',
              icon: Icon(
                Icons.queue_music_rounded,
                color: colors.textPrimary,
                size: 24.0,
              ),
            ),
          ),
          if (onMoreTap != null)
            SizedBox(
              width: 48.0,
              height: 48.0,
              child: IconButton(
                onPressed: onMoreTap,
                tooltip: 'Track options and audio info',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.textPrimary,
                  size: 24.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
