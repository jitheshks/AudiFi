import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/discover_genre_controller.dart';

/// Genre card item definition with custom gradient hue.
class GenreItem {
  const GenreItem({
    required this.name,
    required this.hue,
    required this.apiGenre,
  });

  final String name;
  final double hue;
  final String apiGenre;
}

/// Horizontal scroll of styled genre cards styled after `.gn` in `audifi.html`.
class DiscoverGenresSection extends ConsumerWidget {
  const DiscoverGenresSection({super.key});

  static const List<GenreItem> genres = [
    GenreItem(name: 'Electronic', hue: 260, apiGenre: 'Electronic'),
    GenreItem(name: 'Hip-Hop/Rap', hue: 20, apiGenre: 'Hip-Hop/Rap'),
    GenreItem(name: 'Lo-Fi', hue: 170, apiGenre: 'Lo-Fi'),
    GenreItem(name: 'Ambient', hue: 200, apiGenre: 'Ambient'),
    GenreItem(name: 'Pop', hue: 300, apiGenre: 'Pop'),
    GenreItem(name: 'Rock', hue: 350, apiGenre: 'Rock'),
    GenreItem(name: 'Jazz', hue: 40, apiGenre: 'Jazz'),
    GenreItem(name: 'Techno', hue: 230, apiGenre: 'Techno'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final selectedGenre = ref.watch(discoverGenreProvider);

    return SizedBox(
      height: 84.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: genres.length,
        separatorBuilder: (context, index) => AppSpacing.hGap12,
        itemBuilder: (context, index) {
          final g = genres[index];
          final isSelected = selectedGenre == g.apiGenre;

          final startColor = HSLColor.fromAHSL(
            1.0,
            g.hue,
            0.65,
            0.30,
          ).toColor();
          final endColor = HSLColor.fromAHSL(
            1.0,
            (g.hue + 50) % 360,
            0.60,
            0.18,
          ).toColor();

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Genre: ${g.name}',
            child: InkWell(
              onTap: () {
                ref
                    .read(discoverGenreProvider.notifier)
                    .selectGenre(g.apiGenre);
              },
              borderRadius: BorderRadius.circular(14.0),
              child: AnimatedContainer(
                duration: AppMotion.resolveDuration(
                  AppMotion.durationShort,
                  context: context,
                ),
                curve: AppMotion.curveDecelerate,
                width: 140.0,
                height: 84.0,
                padding: const EdgeInsets.all(12.0),
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [startColor, endColor],
                  ),
                  border: Border.all(
                    color: isSelected ? colors.textPrimary : Colors.transparent,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  g.name,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
