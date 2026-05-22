import 'package:flutter/material.dart';

class ArtboardLogo extends StatelessWidget {
  final double size;
  final double? height;
  const ArtboardLogo({super.key, this.size = 100, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/rr.png',
      width: size,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
