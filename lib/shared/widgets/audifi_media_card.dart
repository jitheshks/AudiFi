import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'audifi_network_image.dart';

/// Reusable media tile card styled strictly after `.tile` in `audifi.html`.
class AudifiMediaCard extends StatelessWidget {
  const AudifiMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.width = 140.0,
    this.height,
    this.isCircle = false,
  });

  /// Primary card label.
  final String title;

  /// Secondary subtitle text.
  final String subtitle;

  /// Remote artwork image URL.
  final String? imageUrl;

  /// Card tap callback.
  final VoidCallback onTap;

  /// Card width. Defaults to 140 dp.
  final double width;

  /// Card total height.
  final double? height;

  /// Whether the image is circular (for artists/users).
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = width.isFinite
            ? width
            : (constraints.maxWidth.isFinite ? constraints.maxWidth : 140.0);
        var imageSize = (availableWidth - 12.0).clamp(0.0, double.infinity);
        if (constraints.maxHeight.isFinite) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final textReservedHeight = (44.0 * textScale) + 20.0;
          final maxImageHeight = constraints.maxHeight - textReservedHeight;
          if (maxImageHeight > 0 && maxImageHeight < imageSize) {
            imageSize = maxImageHeight;
          }
        }

        final imageWidget = AudifiNetworkImage(
          imageUrl: imageUrl,
          width: imageSize,
          height: imageSize,
          isCircle: isCircle,
          borderRadius: 8.0,
        );

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: width,
            height: height,
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: isCircle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (constraints.maxHeight.isFinite)
                  Flexible(child: imageWidget)
                else
                  imageWidget,
                AppSpacing.vGap8,
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isCircle ? TextAlign.center : TextAlign.start,
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.vGap2,
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isCircle ? TextAlign.center : TextAlign.start,
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
