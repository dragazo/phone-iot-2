import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:phone_iot_2/ffi.dart';

const double defaultFontSize = 16;
const double textPadding = 5;
const Color selectColor = Color.fromARGB(50, 255, 255, 255);

const double joystickBorderWidth = 0.035;
const double joystickHandSize = 0.3333;
const Duration joystickUpdateInterval = Duration(milliseconds: 100);

final Uint8List blankImage = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kTtIw0Acxr8+pCItHewg4pChOlkQXzhqFYpQIdQKrTqYXPqCJg1Jiouj4Fpw8LFYdXBx1tXBVRAEHyCuLk6KLlLi/5JCixgPjvvx3X0fd98B/maVqWZwDFA1y8ikkkIuvyqEXhFCBEFMISoxU58TxTQ8x9c9fHy9S/As73N/johSMBngE4hnmW5YxBvE05uWznmfOMbKkkJ8Tjxq0AWJH7kuu/zGueSwn2fGjGxmnjhGLJS6WO5iVjZU4kniuKJqlO/Puaxw3uKsVuusfU/+wnBBW1nmOs0hpLCIJYgQIKOOCqqwkKBVI8VEhvaTHv5Bxy+SSyZXBYwcC6hBheT4wf/gd7dmcWLcTQongZ4X2/4YBkK7QKth29/Htt06AQLPwJXW8deawMwn6Y2OFj8CotvAxXVHk/eAyx1g4EmXDMmRAjT9xSLwfkbflAf6b4G+Nbe39j5OH4AsdZW+AQ4OgZESZa97vLu3u7d/z7T7+wFXoHKclT4nBwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+cHDQQ1KWBVd1EAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAADElEQVQI12NgYGAAAAAEAAEnNCcKAAAAAElFTkSuQmCC');

enum ClickType {
  down, move, up,
}
enum ClickResult {
  none, redraw, requestText, requestImage,
}
enum UpdateSource {
  code, user,
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
BoxFit getFit(ImageFitInfo fit) {
  switch (fit) {
    case ImageFitInfo.Fit: return BoxFit.contain;
    case ImageFitInfo.Zoom: return BoxFit.cover;
    case ImageFitInfo.Stretch: return BoxFit.fill;
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
String encodeClickType(ClickType type) {
  switch (type) {
    case ClickType.down: return 'down';
    case ClickType.move: return 'move';
    case ClickType.up: return 'up';
  }
}

Future<Uint8List> encodeImage(ui.Image img) async {
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}
Future<ui.Image> decodeImage(Uint8List raw) async {
  final c = Completer<ui.Image>();
  ui.decodeImageFromList(raw, (x) => c.complete(x));
  return c.future;
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

mixin TextLike {
  String getText();
  void setText(String value, UpdateSource source);
}
mixin Pressable {
  bool isPressed();
}
mixin PositionLike {
  (double, double) getPosition();
}
mixin ImageLike {
  ui.Image? getImage();
  void setImage(ui.Image? value, UpdateSource source);
}

abstract class CustomControl {
  Size canvasSize = Size.zero;
  String id;

  CustomControl({ required this.id });

  void draw(Canvas canvas);
  bool contains(Offset pos);
  ClickResult handleClick(Offset pos, ClickType type);
}

class CustomLabel extends CustomControl with TextLike {
  double x, y, fontSize;
  TextAlign align;
  Color color;
  String text;
  bool landscape;

  CustomLabel(LabelInfo info) : x = info.x, y = info.y, color = getColor(info.color), text = info.text,
    fontSize = info.fontSize, align = getAlign(info.align), landscape = info.landscape, super(id: info.id);

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
  ClickResult handleClick(Offset pos, ClickType type) => ClickResult.none;

  @override
  String getText() {
    return text;
  }

  @override
  void setText(String value, UpdateSource source) {
    text = value;
  }
}

class CustomButton extends CustomControl with TextLike, Pressable {
  double x, y, width, height, fontSize;
  Color backColor, foreColor;
  ButtonStyleInfo style;
  bool landscape;
  String? event;
  String text;

  bool pressed = false;

  CustomButton(ButtonInfo info) : x = info.x, y = info.y, width = info.width, height = info.height,
    backColor = getColor(info.backColor), foreColor = getColor(info.foreColor), text = info.text, event = info.event,
    fontSize = info.fontSize, style = info.style, landscape = info.landscape, super(id: info.id);

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
        if (pressed) {
          paint.color = selectColor;
          canvas.drawRect(rect, paint);
        }
      case ButtonStyleInfo.Ellipse:
      case ButtonStyleInfo.Circle:
        canvas.drawOval(rect, paint);
        if (pressed) {
          paint.color = selectColor;
          canvas.drawOval(rect, paint);
        }
    }
    drawTextRect(canvas, rect.deflate(textPadding), foreColor, text, fontSize, TextAlign.center, true);
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
        pressed = true;
        if (event != null) {
          api.sendCommand(cmd: RustCommand.injectMessage(msgType: event!, values: [
            ('device', const SimpleValue.number(0)),
            ('id', SimpleValue.string(id)),
          ]));
        }
        return ClickResult.redraw;
      case ClickType.up:
        pressed = false;
        return ClickResult.redraw;
      case ClickType.move:
        return ClickResult.none;
    }
  }

  @override
  String getText() {
    return text;
  }

  @override
  void setText(String value, UpdateSource source) {
    text = value;
  }

  @override
  bool isPressed() {
    return pressed;
  }
}

class CustomTextField extends CustomControl with TextLike {
  double x, y, width, height, fontSize;
  Color backColor, foreColor;
  TextAlign align;
  bool landscape, readonly;
  String? event;
  String text;

  CustomTextField(TextFieldInfo info) : x = info.x, y = info.y, width = info.width, height = info.height,
    backColor = getColor(info.backColor), foreColor = getColor(info.foreColor), text = info.text, readonly = info.readonly,
    event = info.event, fontSize = info.fontSize, align = getAlign(info.align), landscape = info.landscape, super(id: info.id);

  @override
  void draw(Canvas canvas) {
    final paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.color = backColor;
    Rect rect = Rect.fromLTWH(0, 0, width * canvasSize.width / 100, height * canvasSize.height / 100);

    canvas.save();
    canvas.translate(x * canvasSize.width / 100, y * canvasSize.height / 100);
    if (landscape) canvas.rotate(pi / 2);
    canvas.drawRect(rect, paint);
    drawTextRect(canvas, rect.deflate(textPadding), foreColor, text, fontSize, align, false);
    canvas.restore();
  }

  @override
  bool contains(Offset pos) {
    Rect r = Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, width * canvasSize.width / 100, height * canvasSize.height / 100);
    if (landscape) r = rotated(r);
    return r.contains(pos);
  }

  @override
  ClickResult handleClick(Offset pos, ClickType type) {
    return type == ClickType.down && !readonly ? ClickResult.requestText : ClickResult.none;
  }

  @override
  String getText() {
    return text;
  }

  @override
  void setText(String value, UpdateSource source) {
    text = value;

    if (source == UpdateSource.user && event != null) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: event!, values: [
        ('device', const SimpleValue.number(0)),
        ('id', SimpleValue.string(id)),
        ('text', SimpleValue.string(text)),
      ]));
    }
  }
}

class CustomJoystick extends CustomControl with Pressable, PositionLike {
  double x, y, width;
  String? event;
  Color color;
  bool landscape;

  bool pressed = false;
  Offset pos = Offset.zero;
  DateTime nextUpdate = DateTime.now();

  CustomJoystick(JoystickInfo info) : x = info.x, y = info.y, width = info.width,
    event = info.event, color = getColor(info.color), landscape = info.landscape, super(id: info.id);

  @override
  void draw(Canvas canvas) {
    final paint = Paint();
    paint.color = color;
    final w = width * canvasSize.width / 100;
    final r = Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, w, w);
    final c = Offset(r.center.dx + pos.dx * w / 2, r.center.dy + pos.dy * w / 2);
    final g = Rect.fromCenter(center: c, width: w * joystickHandSize, height: w * joystickHandSize);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = max(1, w * joystickBorderWidth);
    canvas.drawOval(r, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawOval(g, paint);
  }

  @override
  bool contains(Offset pos) {
    double w = width * canvasSize.width / 100;
    Rect r = Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, w, w);
    return ellipseContains(r, pos);
  }

  @override
  ClickResult handleClick(Offset pos, ClickType type) {
    final w = width * canvasSize.width / 100;
    double dx = (pos.dx - (x * canvasSize.width / 100 + w / 2)) / (w / 2);
    double dy = (pos.dy - (y * canvasSize.height / 100 + w / 2)) / (w / 2);
    double len = sqrt(dx * dx + dy * dy);
    pos = len <= 1 ? Offset(dx, dy) : Offset(dx / len, dy / len);

    this.pos = type != ClickType.up ? pos : Offset.zero;
    pressed = type != ClickType.up;

    final now = DateTime.now();
    if (event != null && (now.isAfter(nextUpdate) || type == ClickType.up)) {
      nextUpdate = now.add(joystickUpdateInterval);
      final p = getPosition();
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: event!, values: [
        ('device', const SimpleValue.number(0)),
        ('id', SimpleValue.string(id)),
        ('x', SimpleValue.number(p.$1)),
        ('y', SimpleValue.number(p.$2)),
        ('tag', SimpleValue.string(encodeClickType(type))),
      ]));
    }

    return ClickResult.redraw;
  }

  @override
  bool isPressed() {
    return pressed;
  }

  @override
  (double, double) getPosition() {
    return landscape ? (pos.dy, pos.dx) : (pos.dx, -pos.dy);
  }
}

class CustomImageDisplay extends CustomControl with ImageLike {
  double x, y, width, height;
  String? event;
  bool readonly, landscape;
  BoxFit fit;

  ui.Image? image;

  CustomImageDisplay(ImageDisplayInfo info) : x = info.x, y = info.y, width = info.width, height = info.height,
    event = info.event, readonly = info.readonly, landscape = info.landscape, fit = getFit(info.fit), super(id: info.id);

  @override
  void draw(Canvas canvas) {
    final paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.color = Colors.black;
    Rect r = Rect.fromLTWH(0, 0, width * canvasSize.width / 100, height * canvasSize.height / 100);

    canvas.save();
    canvas.translate(x * canvasSize.width / 100, y * canvasSize.height / 100);
    if (landscape) canvas.rotate(pi / 2);
    canvas.drawRect(r, paint);
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: r,
        image: image!,
        fit: fit,
      );
    }
    canvas.restore();
  }

  @override
  bool contains(Offset pos) {
    Rect r = Rect.fromLTWH(x * canvasSize.width / 100, y * canvasSize.height / 100, width * canvasSize.width / 100, height * canvasSize.height / 100);
    if (landscape) r = rotated(r);
    return r.contains(pos);
  }

  @override
  ClickResult handleClick(Offset pos, ClickType type) {
    return type == ClickType.down && !readonly ? ClickResult.requestImage : ClickResult.none;
  }

  @override
  ui.Image? getImage() {
    return image;
  }

  @override
  void setImage(ui.Image? value, UpdateSource source) {
    if (image != value) image?.dispose();
    image = value;

    if (source == UpdateSource.user && event != null) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: event!, values: [
        ('device', const SimpleValue.number(0)),
        ('id', SimpleValue.string(id)),
      ]));
    }
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
