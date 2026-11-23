import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../domain/entities/playlist.dart';
import '../controllers/custom_playlists_controller.dart';

/// Modal dialog prompting the user to create a new custom playlist.
class CreatePlaylistDialog extends ConsumerStatefulWidget {
  const CreatePlaylistDialog({super.key, this.initialTrack});

  /// Optional initial track to include in the newly created playlist.
  final Track? initialTrack;

  /// Helper to present the dialog modally.
  static Future<Playlist?> show(BuildContext context, {Track? initialTrack}) {
    return showDialog<Playlist>(
      context: context,
      builder: (context) => CreatePlaylistDialog(initialTrack: initialTrack),
    );
  }

  @override
  ConsumerState<CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _nameController.addListener(() {
      final isValid = _nameController.text.trim().isNotEmpty;
      if (isValid != _canSubmit) {
        setState(() => _canSubmit = isValid);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final desc = _descController.text.trim();
    final initialTracks = widget.initialTrack != null
        ? [widget.initialTrack!]
        : <Track>[];

    final created = await ref
        .read(customPlaylistsProvider.notifier)
        .createPlaylist(
          name,
          description: desc.isNotEmpty ? desc : null,
          initialTracks: initialTracks,
        );

    if (mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return AlertDialog(
      backgroundColor: colors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: Text(
        'New Playlist',
        style: AppTypography.h2.copyWith(color: colors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: colors.textMuted),
                hintText: 'e.g. Chill Beats',
                hintStyle: TextStyle(
                  color: colors.textMuted.withValues(alpha: 0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.surface2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
              onSubmitted: (_) {
                if (_canSubmit) _submit();
              },
            ),
            AppSpacing.vGap12,
            TextField(
              controller: _descController,
              style: TextStyle(color: colors.textPrimary),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: colors.textMuted),
                hintText: 'Give your playlist a description',
                hintStyle: TextStyle(
                  color: colors.textMuted.withValues(alpha: 0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.surface2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
              onSubmitted: (_) {
                if (_canSubmit) _submit();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        AudifiButton(
          text: 'Create',
          variant: AudifiButtonVariant.primary,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
