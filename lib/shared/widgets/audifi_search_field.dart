import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// Reusable search input field matching the Audifi UI `.sf` specification.
class AudifiSearchField extends StatefulWidget {
  const AudifiSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search tracks, artists, playlists...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<AudifiSearchField> createState() => _AudifiSearchFieldState();
}

class _AudifiSearchFieldState extends State<AudifiSearchField> {
  FocusNode? _internalFocusNode;
  FocusNode? _attachedFocusNode;
  bool _hasText = false;
  bool _isFocused = false;

  /// Resolves the active [FocusNode] lazily so it is always initialized before
  /// [build], listeners, or tap callbacks access it (including after hot reload).
  FocusNode get _effectiveFocusNode {
    final node = widget.focusNode ?? (_internalFocusNode ??= FocusNode());
    if (!identical(_attachedFocusNode, node)) {
      _attachedFocusNode?.removeListener(_handleFocusChange);
      _attachedFocusNode = node;
      node.addListener(_handleFocusChange);
      _isFocused = node.hasFocus;
    }
    return node;
  }

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_handleTextChange);
    _effectiveFocusNode;
  }

  @override
  void didUpdateWidget(covariant AudifiSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
      _hasText = widget.controller.text.isNotEmpty;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _attachedFocusNode?.removeListener(_handleFocusChange);
      _attachedFocusNode = null;
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _attachedFocusNode?.removeListener(_handleFocusChange);
    _attachedFocusNode = null;
    _internalFocusNode?.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final isFocused = _effectiveFocusNode.hasFocus;
    if (isFocused != _isFocused) {
      setState(() => _isFocused = isFocused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final focusNode = _effectiveFocusNode;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: AnimatedContainer(
        duration: AppMotion.resolveDuration(
          AppMotion.durationFast,
          context: context,
        ),
        curve: AppMotion.curveDecelerate,
        constraints: const BoxConstraints(minHeight: 48.0),
        decoration: BoxDecoration(
          color: colors.surface1,
          borderRadius: AppRadius.inputBorder,
          border: Border.all(
            color: _isFocused
                ? colors.accent.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: _isFocused ? colors.accent : colors.textMuted,
              size: 22.0,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: focusNode,
                autofocus: widget.autofocus,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
                cursorColor: colors.accent,
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTypography.body.copyWith(
                    color: colors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
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
      ),
    );
  }
}
