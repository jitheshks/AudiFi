import 'package:material_ui/material_ui.dart';

/// Custom icon painter rendering the 5-bar equalizer wave icon (`wave` in `audifi.html`).
class AudifiWaveIcon extends StatelessWidget {
  const AudifiWaveIcon({super.key, this.size = 24.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.white;

    return CustomPaint(
      size: Size(size, size),
      painter: _WaveIconPainter(color: effectiveColor),
    );
  }
}

class _WaveIconPainter extends CustomPainter {
  const _WaveIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    // 5 vertical wave bars matching SVG path:
    // M3 11h2v2H3zm4-4h2v10H7zm4-4h2v18h-2zm4 4h2v10h-2zm4 4h2v2h-2z
    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.0 * scaleX, 11.0 * scaleY, 2.0 * scaleX, 2.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );
    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(7.0 * scaleX, 7.0 * scaleY, 2.0 * scaleX, 10.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );
    final r3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(11.0 * scaleX, 3.0 * scaleY, 2.0 * scaleX, 18.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );
    final r4 = RRect.fromRectAndRadius(
      Rect.fromLTWH(15.0 * scaleX, 7.0 * scaleY, 2.0 * scaleX, 10.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );
    final r5 = RRect.fromRectAndRadius(
      Rect.fromLTWH(19.0 * scaleX, 11.0 * scaleY, 2.0 * scaleX, 2.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );

    canvas.drawRRect(r1, paint);
    canvas.drawRRect(r2, paint);
    canvas.drawRRect(r3, paint);
    canvas.drawRRect(r4, paint);
    canvas.drawRRect(r5, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom icon painter rendering the 3-book library icon (`lib` in `audifi.html`).
class AudifiLibraryIcon extends StatelessWidget {
  const AudifiLibraryIcon({super.key, this.size = 24.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.white;

    return CustomPaint(
      size: Size(size, size),
      painter: _LibraryIconPainter(color: effectiveColor),
    );
  }
}

class _LibraryIconPainter extends CustomPainter {
  const _LibraryIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    // SVG: M4 4h3v16H4zm5 0h3v16H9zm5 2l3-1 3 14-3 1z
    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(4.0 * scaleX, 4.0 * scaleY, 3.0 * scaleX, 16.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );
    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(9.0 * scaleX, 4.0 * scaleY, 3.0 * scaleX, 16.0 * scaleY),
      Radius.circular(1.0 * scaleX),
    );

    canvas.drawRRect(r1, paint);
    canvas.drawRRect(r2, paint);

    // Tilted book
    final path = Path();
    path.moveTo(14.0 * scaleX, 6.0 * scaleY);
    path.lineTo(17.0 * scaleX, 5.0 * scaleY);
    path.lineTo(20.0 * scaleX, 19.0 * scaleY);
    path.lineTo(17.0 * scaleX, 20.0 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LibraryIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
