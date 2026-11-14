import 'package:flutter/material.dart';

/// Colourful confetti for the "Booking Confirmed" screen.
class TourConfettiPainter extends CustomPainter {
  const TourConfettiPainter();

  static const List<List<double>> _pieces = [
    [.08, .06], [.18, .14], [.30, .05], [.42, .12], [.60, .04], [.72, .13],
    [.84, .06], [.93, .16], [.12, .27], [.24, .34], [.78, .28], [.90, .36],
    [.05, .44], [.66, .22], [.50, .26], [.95, .48],
  ];
  static const List<Color> _colors = [
    Color(0xFF22C55E), Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFFFFC53D),
    Color(0xFFB36BFF), Color(0xFFFF8FB1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pieces.length; i++) {
      final paint = Paint()..color = _colors[i % _colors.length];
      final c = Offset(size.width * _pieces[i][0], size.height * _pieces[i][1]);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * .7);
      if (i % 4 == 0) {
        canvas.drawCircle(Offset.zero, 3, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-6, -2.5, 12, 5), const Radius.circular(2)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
