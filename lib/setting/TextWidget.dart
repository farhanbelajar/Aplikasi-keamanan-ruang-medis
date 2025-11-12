import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final FontWeight fontWeight;
  final double? letterSpace;

  const TextWidget(
      this.text,
      this.size,
      this.color,
      this.fontWeight, {
        super.key,
        this.letterSpace,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpace ?? 0,
      ),
    );
  }
}
