import 'package:flutter/material.dart';

extension ClayColorExtension on Color {
  Color lighten(double percent) {
    return Color.lerp(this, Colors.white, percent / 100)!;
  }

  Color darken(double percent) {
    return Color.lerp(this, Colors.black, percent / 100)!;
  }
}
