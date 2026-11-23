import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';

/// Micro progress indicator bar rendered along the bottom edge of the mini-player.
/// Directly mirrors `.mini .prog` in `audifi.html`.
class MiniPlayerProgress extends StatelessWidget {
  const MiniPlayerProgress({super.key, required this.progress});

  /// Normalized progress value [0.0 - 1.0].
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Semantics(
      label: 'Playback progress',
      value: '${(progress * 100).toInt()}%',
      child: SizedBox(
        height: 2.0,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: colors.surface2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          minHeight: 2.0,
        ),
      ),
    );
  }
}
