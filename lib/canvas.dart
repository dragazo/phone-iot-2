import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

Color getColor(CustomColor color) {
  return Color.fromARGB(color.a, color.r, color.g, color.b);
}
Rect getRect(Size canvasSize, double x, double y, double width, double height) {
  return Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, width * canvasSize.width / 100, height * canvasSize.height / 100);
}

void drawButton(Canvas canvas, Size canvasSize, CustomButton control) {
  final paint = Paint();
  paint.style = PaintingStyle.fill;
  paint.color = getColor(control.backColor);
  final rect = getRect(canvasSize, control.x, control.y, control.width, control.height);
  canvas.drawRect(rect, paint);
}

class ControlsCanvas extends CustomPainter {
  List<CustomControl> controls;

  ControlsCanvas(this.controls);

  @override
  void paint(Canvas canvas, Size size) {
    for (final x in controls) {
      if (x is CustomControl_Button) {
        drawButton(canvas, size, x.field0);
      } else {
        throw FormatException('unknown control type $x');
      }
    }
  }

  @override
  bool shouldRepaint(ControlsCanvas oldDelegate) {
    return false;
  }
}
