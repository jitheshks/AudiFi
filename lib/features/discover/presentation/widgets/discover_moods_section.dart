import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../search/presentation/controllers/search_controller.dart';

/// Horizontal chip list for mood-based discovery reflecting verified Audius moods.
class DiscoverMoodsSection extends ConsumerWidget {
  const DiscoverMoodsSection({super.key});

  static const List<({String name, IconData icon})> moods = [
    (name: 'Upbeat', icon: Icons.celebration_rounded),
    (name: 'Energizing', icon: Icons.bolt_rounded),
    (name: 'Peaceful', icon: Icons.spa_rounded),
    (name: 'Romantic', icon: Icons.favorite_rounded),
    (name: 'Cool', icon: Icons.nightlife_rounded),
    (name: 'Fiery', icon: Icons.local_fire_department_rounded),
    (name: 'Melancholy', icon: Icons.cloudy_snowing),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;

    return SizedBox(
      height: 40.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: moods.length,
        separatorBuilder: (context, index) => AppSpacing.hGap8,
        itemBuilder: (context, index) {
          final mood = moods[index];
          return ActionChip(
            avatar: Icon(mood.icon, size: 16.0, color: colors.accent),
            label: Text(
              mood.name,
              style: AppTypography.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: colors.surface2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(color: colors.surface2),
            ),
            onPressed: () {
              ref.read(searchControllerProvider.notifier).search(mood.name);
              context.go(RoutePaths.search);
            },
          );
        },
      ),
    );
  }
}
