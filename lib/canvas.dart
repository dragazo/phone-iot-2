import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

const double defaultFontSize = 16;

Color getColor(ColorInfo color) {
  return Color.fromARGB(color.a, color.r, color.g, color.b);
}
TextAlign getAlign(TextAlignInfo align) {
  switch (align) {
    case TextAlignInfo.Left: return TextAlign.left;
    case TextAlignInfo.Center: return TextAlign.center;
    case TextAlignInfo.Right: return TextAlign.right;
  }
}

void drawTextRect(Canvas canvas, Rect rect, Color color, String text, double fontSize, TextAlign align, bool vCenter) {
  final parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: align));
  parBuilder.pushStyle(ui.TextStyle(color: color, fontSize: defaultFontSize * fontSize));
  parBuilder.addText(text);
  final par = parBuilder.build();
  par.layout(ui.ParagraphConstraints(width: rect.width));
  final vOffset = vCenter ? (rect.height - min(par.height, rect.height)) / 2 : 0;
  canvas.save();
  canvas.clipRect(rect);
  canvas.drawParagraph(par, Offset(rect.left, rect.top + vOffset));
  canvas.restore();
}

abstract class CustomControl {
  Size canvasSize = Size.zero;
  void draw(Canvas canvas);
}
class CustomButton extends CustomControl {
  double x, y, width, height, fontSize;
  Color backColor, foreColor;
  ButtonStyleInfo style;
  bool landscape;
  String? event;
  String text;

  CustomButton(ButtonInfo info) : x = info.x, y = info.y, width = info.width, height = info.height,
    backColor = getColor(info.backColor), foreColor = getColor(info.foreColor), text = info.text,
    event = info.event, fontSize = info.fontSize, style = info.style, landscape = info.landscape;

  @override
  void draw(Canvas canvas) {
    final paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.color = backColor;
    double w = width * canvasSize.width / 100;
    double h = style == ButtonStyleInfo.Square || style == ButtonStyleInfo.Circle ? w : height * canvasSize.height / 100;
    Rect rect = Rect.fromLTWH(0, 0, w, h);

    canvas.save();
    canvas.translate(x * canvasSize.width / 100, y * canvasSize.height / 100);
    if (landscape) canvas.rotate(pi / 2);
    switch (style) {
      case ButtonStyleInfo.Rectangle:
      case ButtonStyleInfo.Square:
        canvas.drawRect(rect, paint);
      case ButtonStyleInfo.Ellipse:
      case ButtonStyleInfo.Circle:
        canvas.drawOval(rect, paint);
    }
    drawTextRect(canvas, rect, foreColor, text, fontSize, TextAlign.center, true);
    canvas.restore();
  }
}
class CustomLabel extends CustomControl {
  double x, y, fontSize;
  TextAlign align;
  Color color;
  String text;
  bool landscape;

  CustomLabel(LabelInfo info) : x = info.x, y = info.y, color = getColor(info.color), text = info.text,
    fontSize = info.fontSize, align = getAlign(info.align), landscape = info.landscape;

  @override
  void draw(Canvas canvas) {

  }
}

class ControlsCanvas extends CustomPainter {
  Map<String, CustomControl> controls;

  ControlsCanvas(this.controls);

  @override
  void paint(Canvas canvas, Size size) {
    for (final x in controls.values) {
      x.canvasSize = size;
      x.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(ControlsCanvas oldDelegate) {
    return false;
  }
}
