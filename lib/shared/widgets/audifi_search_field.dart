import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// Reusable search input field matching the Audifi UI `.sf` specification.
class AudifiSearchField extends StatefulWidget {
  const AudifiSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search tracks, artists, playlists...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<AudifiSearchField> createState() => _AudifiSearchFieldState();
}

class _AudifiSearchFieldState extends State<AudifiSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: AppRadius.inputBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.textMuted, size: 22.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: widget.controller,
              autofocus: widget.autofocus,
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              cursorColor: colors.accent,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.body.copyWith(color: colors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onClear?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textMuted,
                  size: 20.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
