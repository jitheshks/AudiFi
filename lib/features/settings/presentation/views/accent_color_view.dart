import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_page_container.dart';

/// Accent color selection view faithfully matching `accent_colour.png` and `audifi.html`.
class AccentColorView extends ConsumerWidget {
  const AccentColorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final currentAccent = ref.watch(accentColorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: AudifiPageContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safe Area Top Padding
            SizedBox(height: MediaQuery.paddingOf(context).top + 8.0),

            // Back button "< Appearance"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) context.pop();
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '‹ Appearance',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Heading: Accent color
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
              child: Text(
                'Accent color',
                style: AppTypography.h1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Section: PREVIEW
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
              child: Text(
                'PREVIEW',
                style: TextStyle(
                  fontSize: 12.0,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AudifiCard(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Circular Play Button matching accent_colour.png
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: currentAccent.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Accent Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2.0),
                            child: Container(
                              height: 4.0,
                              color: colors.surface2,
                              child: FractionallySizedBox(
                                widthFactor: 0.42,
                                alignment: Alignment.centerLeft,
                                child: Container(color: currentAccent.color),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Your accent color',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.vGap24,

            // Section: COLORS
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
              child: Text(
                'COLORS',
                style: TextStyle(
                  fontSize: 12.0,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AudifiCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: List.generate(AudifiAccent.options.length, (index) {
                    final option = AudifiAccent.options[index];
                    final isSelected = option.id == currentAccent.id;
                    final isLast = index == AudifiAccent.options.length - 1;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          button: true,
                          selected: isSelected,
                          label: 'Select accent color: ${option.name}',
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(accentColorProvider.notifier)
                                  .setAccent(option);
                            },
                            borderRadius: BorderRadius.vertical(
                              top: index == 0
                                  ? const Radius.circular(18.0)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(18.0)
                                  : Radius.zero,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 52.0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  // Color Circle Swatch
                                  Container(
                                    width: 30.0,
                                    height: 30.0,
                                    decoration: BoxDecoration(
                                      color: option.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 14.0),
                                  Expanded(
                                    child: Text(
                                      option.name,
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      color: colors.accent,
                                      size: 22.0,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            color: colors.surface2.withValues(alpha: 0.6),
                            height: 1.0,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }
}
