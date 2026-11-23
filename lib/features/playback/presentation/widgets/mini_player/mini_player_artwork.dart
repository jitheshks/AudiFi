import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/audifi_network_image.dart';

/// Thumbnail artwork widget for the persistent mini-player.
class MiniPlayerArtwork extends StatelessWidget {
  const MiniPlayerArtwork({
    super.key,
    required this.imageUrl,
    this.size = 46.0,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Semantics(
      label: 'Track artwork',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: size,
          height: size,
          color: colors.surface2,
          child: AudifiNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            borderRadius: 8.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
