import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

Color getColor(CustomColor color) {
  return Color.fromARGB(color.a, color.r, color.g, color.b);
}
Rect getRect(Size canvasSize, double x, double y, double width, double height) {
  return Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, width * canvasSize.width / 100, height * canvasSize.height / 100);
}

void drawText(Canvas canvas, Rect rect, Color color, String text, TextAlign align) {
  final parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: align));
  parBuilder.pushStyle(ui.TextStyle(color: color));
  parBuilder.addText(text);
  final par = parBuilder.build();
  par.layout(ui.ParagraphConstraints(width: rect.width));
  canvas.drawParagraph(par, Offset(rect.left, rect.top));
}

void drawButton(Canvas canvas, Size canvasSize, CustomButton control) {
  final paint = Paint();
  paint.style = PaintingStyle.fill;
  paint.color = getColor(control.backColor);
  final rect = getRect(canvasSize, control.x, control.y, control.width, control.height);
  canvas.drawRect(rect, paint);
  drawText(canvas, rect, getColor(control.foreColor), control.text, TextAlign.center);
}
void drawLabel(Canvas canvas, Size canvasSize, CustomLabel control) {

}

class ControlsCanvas extends CustomPainter {
  List<CustomControl> controls;

  ControlsCanvas(this.controls);

  @override
  void paint(Canvas canvas, Size size) {
    for (final x in controls.reversed) {
      x.when(
        button: (field0) => drawButton(canvas, size, field0),
        label: (field0) => drawLabel(canvas, size, field0),
      );
    }
  }

  @override
  bool shouldRepaint(ControlsCanvas oldDelegate) {
    return false;
  }
}
