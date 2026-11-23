import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Reusable network image component with shimmer-like placeholder and fallback error icon.
class AudifiNetworkImage extends StatelessWidget {
  const AudifiNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.isCircle = false,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.music_note_rounded,
  });

  /// Remote image URL to display.
  final String? imageUrl;

  /// Width constraint.
  final double? width;

  /// Height constraint.
  final double? height;

  /// Border radius for rectangular images. Can be a [double] (e.g. 8.0) or [BorderRadiusGeometry].
  final dynamic borderRadius;

  /// Whether the image should be rendered as a circle (avatar).
  final bool isCircle;

  /// BoxFit property for image scaling.
  final BoxFit fit;

  /// Fallback icon if loading fails or URL is null.
  final IconData fallbackIcon;

  BorderRadiusGeometry get _resolvedBorderRadius {
    if (borderRadius is BorderRadiusGeometry) {
      return borderRadius as BorderRadiusGeometry;
    }
    if (borderRadius is num) {
      return BorderRadius.circular((borderRadius as num).toDouble());
    }
    return BorderRadius.circular(8.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surface2,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : _resolvedBorderRadius,
      ),
      child: Icon(
        fallbackIcon,
        color: colors.textMuted,
        size: (width != null && height != null)
            ? (width! * 0.4).clamp(16.0, 48.0)
            : 24.0,
      ),
    );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return placeholder;
    }

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final targetCacheWidth = width != null
        ? (width! * dpr).toInt().clamp(64, 1024)
        : null;
    final targetCacheHeight = height != null
        ? (height! * dpr).toInt().clamp(64, 1024)
        : null;

    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: targetCacheWidth,
      cacheHeight: targetCacheHeight,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
    );

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    return ClipRRect(borderRadius: _resolvedBorderRadius, child: imageWidget);
  }
}
