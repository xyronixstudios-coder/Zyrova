import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final String type;
  final String color1;
  final String color2;
  final String pattern;

  const BannerWidget({
    super.key,
    required this.type,
    required this.color1,
    required this.color2,
    required this.pattern,
  });

  Color _hex(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final c1 = _hex(color1);
    final c2 = _hex(color2);

    switch (type) {
      case 'gradient':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2],
            ),
          ),
        );

      case 'pattern':
        return ClipRect(
          child: Container(
            color: c1,
            child: CustomPaint(
              painter: _PatternPainter(
                pattern: pattern,
                color: c2,
              ),
              size: Size.infinite,
            ),
          ),
        );

      default:
        return Container(color: c1);
    }
  }
}

class _PatternPainter extends CustomPainter {
  final String pattern;
  final Color color;

  _PatternPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 🔥 OPAK RENK (0.9 = neredeyse tam)
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;   // 🔥 daha kalın

    switch (pattern) {
      case 'dots':
        const spacing = 20.0;
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 3, paint);   // 🔥 daha büyük
          }
        }
        break;

      case 'stripes':
        const stripeWidth = 16.0;   // 🔥 daha kalın
        final path = Path();
        for (double x = -size.height;
            x < size.width;
            x += stripeWidth * 2) {
          path.moveTo(x, 0);
          path.lineTo(x + stripeWidth, 0);
          path.lineTo(x + stripeWidth + size.height, size.height);
          path.lineTo(x + size.height, size.height);
          path.close();
        }
        canvas.drawPath(path, paint);
        break;

      case 'waves':
        for (double y = 0; y < size.height + 20; y += 24) {
          final path = Path()..moveTo(0, y);
          for (double x = 0; x <= size.width; x += 8) {
            final dy = ((x ~/ 16) % 2 == 0) ? -5.0 : 5.0;
            path.lineTo(x, y + dy);
          }
          canvas.drawPath(path, strokePaint);
        }
        break;

      case 'circles':
        const radius = 10.0;
        const spacing = 36.0;
        for (double x = spacing / 2; x < size.width; x += spacing) {
          for (double y = spacing / 2; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), radius, strokePaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}
