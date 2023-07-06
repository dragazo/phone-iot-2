import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

Color getColor(CustomColor color) {
  return Color.fromARGB(color.a, color.r, color.g, color.b);
}

class ControlsCanvas extends CustomPainter {
  CustomControls controls;

  ControlsCanvas(this.controls);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final button in controls.buttons) {
      paint.color = getColor(button.backColor);
      // canvas.drawRect(rect, paint)
    }
  }

  @override
  bool shouldRepaint(ControlsCanvas oldDelegate) {
    return false;
  }
}
