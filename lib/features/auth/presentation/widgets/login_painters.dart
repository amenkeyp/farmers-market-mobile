import 'package:flutter/material.dart';

/// Smooth bezier wave clipper for the header-to-body transition.
///
/// Creates a flowing S-curve at the bottom edge of the header,
/// producing a natural wave that separates the gradient from
/// the white content area.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;

    final path = Path()
      ..lineTo(0, h - 56)
      // First wave trough: curves down past h on the left side
      ..quadraticBezierTo(w * 0.25, h + 16, w * 0.5, h - 24)
      // Second wave crest: curves back up on the right side
      ..quadraticBezierTo(w * 0.75, h - 64, w, h - 12)
      ..lineTo(w, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints subtle decorative circles over the header gradient
/// to add depth and simulate a background-image overlay (opacity ~0.15).
///
/// Uses multiple translucent white circles at varying sizes and
/// opacities to create a layered, professional fintech-style
/// background effect without requiring an actual image asset.
class HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large circle – top right (bokeh-style depth)
    paint.color = const Color(0x12FFFFFF); // ~7% white
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.08),
      size.width * 0.38,
      paint,
    );

    // Medium circle – left center
    paint.color = const Color(0x0DFFFFFF); // ~5% white
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 0.52),
      size.width * 0.26,
      paint,
    );

    // Small circle – bottom center-right
    paint.color = const Color(0x0AFFFFFF); // ~4% white
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.72),
      size.width * 0.16,
      paint,
    );

    // Accent dot – upper left
    paint.color = const Color(0x14FFFFFF); // ~8% white
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.18), 18, paint);

    // Accent dot – right center
    paint.color = const Color(0x10FFFFFF); // ~6% white
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.38), 12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
