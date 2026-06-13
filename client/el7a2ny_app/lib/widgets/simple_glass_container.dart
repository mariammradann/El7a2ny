// lib/widgets/simple_glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A lightweight glass‑morphism container.
///
/// Parameters:
/// - [borderRadius] – radius of the rounded corners.
/// - [blur] – sigmaX/Y for the backdrop blur effect.
/// - [opacity] – background color opacity (0.0 – 1.0).
/// - [child] – widget tree displayed inside the container.
class SimpleGlassContainer extends StatelessWidget {
  final double borderRadius;
  final double blur;
  final double opacity;
  final Widget child;

  const SimpleGlassContainer({
    Key? key,
    this.borderRadius = 12.0,
    this.blur = 10.0,
    this.opacity = 0.15,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
