import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

const double defaultFontSize = 16;
const Color selectColor = Color.fromARGB(50, 255, 255, 255);

enum ClickType {
  down, move, up,
}
enum ClickResult {
  redraw, noRedraw,
}

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

Rect rotated(Rect r) {
  return Rect.fromLTWH(r.left - r.height, r.top, r.height, r.width);
}
bool ellipseContains(Rect r, Offset pos) {
  double rx = r.width / 2, ry = r.height / 2;
  double cx = r.left + rx, cy = r.top + ry;
  double px = pos.dx - cx, py = pos.dy - cy;
  return (px * px) / (rx * rx) + (py * py) / (ry * ry) <= 1;
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
void drawTextPos(Canvas canvas, Offset offset, Color color, String text, double fontSize, TextAlign align) {
  final parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle());
  parBuilder.pushStyle(ui.TextStyle(color: color, fontSize: defaultFontSize * fontSize));
  parBuilder.addText(text);
  final par = parBuilder.build();
  par.layout(const ui.ParagraphConstraints(width: double.infinity));
  double dx;
  switch (align) {
    case TextAlign.left:
    case TextAlign.justify:
    case TextAlign.start:
      dx = 0;
    case TextAlign.center:
      dx = -par.longestLine / 2;
    case TextAlign.right:
    case TextAlign.end:
      dx = -par.longestLine;
  }
  canvas.drawParagraph(par, Offset(offset.dx + dx, offset.dy));
}

abstract class CustomControl {
  Size canvasSize = Size.zero;

  void draw(Canvas canvas);
  bool contains(Offset pos);
  ClickResult handleClick(Offset pos, ClickType type);
}
class CustomButton extends CustomControl {
  double x, y, width, height, fontSize;
  Color backColor, foreColor;
  ButtonStyleInfo style;
  bool landscape;
  String? event;
  String id, text;

  bool clicked = false;

  CustomButton(ButtonInfo info) : id = info.id, x = info.x, y = info.y, width = info.width, height = info.height,
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
        if (clicked) {
          paint.color = selectColor;
          canvas.drawRect(rect, paint);
        }
      case ButtonStyleInfo.Ellipse:
      case ButtonStyleInfo.Circle:
        canvas.drawOval(rect, paint);
        if (clicked) {
          paint.color = selectColor;
          canvas.drawOval(rect, paint);
        }
    }
    drawTextRect(canvas, rect, foreColor, text, fontSize, TextAlign.center, true);
    canvas.restore();
  }

  @override
  bool contains(Offset pos) {
    Rect r = Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, width * canvasSize.width / 100, height * canvasSize.height / 100);
    if (style == ButtonStyleInfo.Square || style == ButtonStyleInfo.Circle) {
        r = Rect.fromLTWH(r.left, r.top, r.width, r.width);
    }
    if (landscape) r = rotated(r);
    switch (style) {
      case ButtonStyleInfo.Rectangle:
      case ButtonStyleInfo.Square:
        return r.contains(pos);
      case ButtonStyleInfo.Ellipse:
      case ButtonStyleInfo.Circle:
        return ellipseContains(r, pos);
    }
  }

  @override
  ClickResult handleClick(Offset pos, ClickType type) {
    switch (type) {
      case ClickType.down:
        clicked = true;
        if (event != null) {
          api.sendCommand(cmd: RustCommand.injectMessage(msgType: event!, values: [('device', const SimpleValue.number(0)), ('id', SimpleValue.string(id))]));
        }
        return ClickResult.redraw;
      case ClickType.up:
        clicked = false;
        return ClickResult.redraw;
      case ClickType.move:
        return ClickResult.noRedraw;
    }
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
    canvas.save();
    canvas.translate(x * canvasSize.width / 100, y * canvasSize.height / 100);
    if (landscape) canvas.rotate(pi / 2);
    drawTextPos(canvas, Offset.zero, color, text, fontSize, align);
    canvas.restore();
  }

  @override
  bool contains(Offset pos) => false;

  @override
  ClickResult handleClick(Offset pos, ClickType type) => ClickResult.noRedraw;
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
