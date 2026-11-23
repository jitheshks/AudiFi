import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Progress scrubber bar and time labels for the Now Playing view.
class NowPlayingProgress extends StatefulWidget {
  const NowPlayingProgress({
    super.key,
    required this.position,
    required this.duration,
    required this.formattedPosition,
    required this.formattedRemaining,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final String formattedPosition;
  final String formattedRemaining;
  final ValueChanged<Duration> onSeek;

  @override
  State<NowPlayingProgress> createState() => _NowPlayingProgressState();
}

class _NowPlayingProgressState extends State<NowPlayingProgress> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final maxMs = widget.duration.inMilliseconds.toDouble();
    final currentMs = (_dragValue ?? widget.position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Track progress slider',
          slider: true,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.surface2,
              thumbColor: colors.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              overlayColor: colors.accent.withValues(alpha: 0.16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              min: 0.0,
              max: maxMs > 0 ? maxMs : 1.0,
              value: currentMs,
              semanticFormatterCallback: (val) {
                final current = Duration(milliseconds: val.toInt());
                return '${current.inMinutes} minutes ${current.inSeconds.remainder(60)} seconds of '
                    '${widget.duration.inMinutes} minutes ${widget.duration.inSeconds.remainder(60)} seconds';
              },
              onChanged: maxMs > 0
                  ? (val) {
                      setState(() {
                        _dragValue = val;
                      });
                    }
                  : null,
              onChangeEnd: maxMs > 0
                  ? (val) {
                      widget.onSeek(Duration(milliseconds: val.toInt()));
                      setState(() {
                        _dragValue = null;
                      });
                    }
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Elapsed time ${widget.formattedPosition}',
                child: Text(
                  widget.formattedPosition,
                  style: AppTypography.micro.copyWith(color: colors.textMuted),
                ),
              ),
              Semantics(
                label:
                    'Remaining time ${widget.formattedRemaining.replaceFirst("-", "")}',
                child: Text(
                  widget.formattedRemaining,
                  style: AppTypography.micro.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
