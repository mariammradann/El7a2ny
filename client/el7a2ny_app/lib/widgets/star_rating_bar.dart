import 'package:flutter/material.dart';

class StarRatingBar extends StatefulWidget {
  final int maxRating;
  final double initialRating;
  final Function(double) onRatingChanged;
  final double itemSize;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingBar({
    super.key,
    this.maxRating = 5,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.itemSize = 32.0,
    this.activeColor = const Color(0xFFF59E0B),
    this.inactiveColor = const Color(0xFFE5E7EB),
  });

  @override
  State<StarRatingBar> createState() => _StarRatingBarState();
}

class _StarRatingBarState extends State<StarRatingBar> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1.0;
            });
            widget.onRatingChanged(_currentRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              index < _currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: index < _currentRating ? widget.activeColor : widget.inactiveColor,
              size: widget.itemSize,
            ),
          ),
        );
      }),
    );
  }
}
