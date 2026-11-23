import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Reusable tab item specification for [AudifiUnderlinedTabs].
class AudifiTabItem<T> {
  const AudifiTabItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Underlined tabs navigation component faithfully reproducing `.tabs` in `audifi.html`
/// and the screenshots (`discover.png`, `search.png`, `library.png`).
class AudifiUnderlinedTabs<T> extends StatelessWidget {
  const AudifiUnderlinedTabs({
    super.key,
    required this.tabs,
    required this.selectedValue,
    required this.onTabSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  final List<AudifiTabItem<T>> tabs;
  final T selectedValue;
  final ValueChanged<T> onTabSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = tab.value == selectedValue;

          return Semantics(
            button: true,
            selected: isSelected,
            label: '${tab.label} tab',
            child: InkWell(
              onTap: () => onTabSelected(tab.value),
              borderRadius: BorderRadius.circular(8.0),
              child: AnimatedContainer(
                duration: AppMotion.resolveDuration(
                  AppMotion.durationShort,
                  context: context,
                ),
                curve: AppMotion.curveDecelerate,
                constraints: const BoxConstraints(
                  minWidth: 44.0,
                  minHeight: 44.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? colors.accent : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.resolveDuration(
                    AppMotion.durationShort,
                    context: context,
                  ),
                  curve: AppMotion.curveDecelerate,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colors.textPrimary : colors.textMuted,
                  ),
                  child: Text(tab.label),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
