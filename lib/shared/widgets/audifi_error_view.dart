import 'package:material_ui/material_ui.dart';

import '../../core/errors/failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'audifi_button.dart';

/// Reusable user-facing error presentation view conforming to `.note` alert styling.
/// Displays safe, friendly messages and an optional retry action.
class AudifiErrorView extends StatelessWidget {
  const AudifiErrorView({
    super.key,
    this.failure,
    this.message,
    this.title = 'Unable to Load Content',
    this.onRetry,
  });

  /// Optional typed domain failure.
  final Failure? failure;

  /// Custom fallback or explicit error message.
  final String? message;

  /// Header title for the error.
  final String title;

  /// Callback to retry the failed operation.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final displayMessage =
        failure?.message ??
        message ??
        'Something went wrong while fetching data. Please check your connection and try again.';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colors.surface2, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28.0,
            ),
          ),
          AppSpacing.vGap12,
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: colors.textPrimary),
          ),
          AppSpacing.vGap6,
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textMuted),
          ),
          if (onRetry != null) ...[
            AppSpacing.vGap16,
            AudifiButton(
              text: 'Try Again',
              onPressed: onRetry,
              variant: AudifiButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}
