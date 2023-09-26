import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'ffi.dart';

import 'package:image/image.dart' as image;

String? tryStringFromBytes(Uint8List src) {
  try {
    return utf8.decode(src);
  } catch (e) {
    return null;
  }
}
List<int> stringToBEBytes(String src) {
  return utf8.encode(src);
}

ColorInfo colorFromBEBytes(Uint8List src) {
  assert(src.length == 4);
  return ColorInfo(a: src[0], r: src[1], g: src[2], b: src[3]);
}
TextAlignInfo textAlignFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return TextAlignInfo.Center;
    case 2: return TextAlignInfo.Right;
    default: return TextAlignInfo.Left;
  }
}
ButtonStyleInfo buttonStyleFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return ButtonStyleInfo.Ellipse;
    case 2: return ButtonStyleInfo.Square;
    case 3: return ButtonStyleInfo.Circle;
    default: return ButtonStyleInfo.Rectangle;
  }
}
TouchpadStyleInfo touchpadStyleFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return TouchpadStyleInfo.Square;
    default: return TouchpadStyleInfo.Rectangle;
  }
}
SliderStyleInfo sliderStyleFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return SliderStyleInfo.Progress;
    default: return SliderStyleInfo.Slider;
  }
}
ToggleStyleInfo toggleStyleFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return ToggleStyleInfo.Checkbox;
    default: return ToggleStyleInfo.Switch;
  }
}
ImageFitInfo imageFitFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return ImageFitInfo.Zoom;
    case 2: return ImageFitInfo.Stretch;
    default: return ImageFitInfo.Fit;
  }
}

int u64FromBEBytes(Uint8List src) {
  assert(src.length == 8);
  return ByteData.view(src.buffer).getUint64(0, Endian.big);
}
int u32FromBEBytes(Uint8List src) {
  assert(src.length == 4);
  return ByteData.view(src.buffer).getUint32(0, Endian.big);
}
double f32FromBEBytes(Uint8List src) {
  assert(src.length == 4);
  return ByteData.view(src.buffer).getFloat32(0, Endian.big);
}

Uint8List u32ToBEBytes(int src) {
  final res = Uint8List(4);
  ByteData.view(res.buffer).setUint32(0, src, Endian.big);
  return res;
}
Uint8List f64ToBEBytes(double src) {
  final res = Uint8List(8);
  ByteData.view(res.buffer).setFloat64(0, src, Endian.big);
  return res;
}
Uint8List f32ToBEBytes(double src) {
  final res = Uint8List(4);
  ByteData.view(res.buffer).setFloat32(0, src, Endian.big);
  return res;
}

Future<Uint8List> encodeImage(ui.Image img) async {
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}
Future<ui.Image> decodeImage(Uint8List raw) async {
  final c = Completer<ui.Image>();
  ui.decodeImageFromList(raw, (x) => c.complete(x));
  return c.future;
}

const maxImageBytes = 4 * 64 * 1024;
Future<Uint8List> packageImageForUdp(ui.Image img) async {
  final rawEncoded = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  image.Image wrapped = image.Image.fromBytes(width: img.width, height: img.height, bytes: rawEncoded.buffer, order: image.ChannelOrder.rgba);

  final rawBytes = 4 * img.width * img.height;
  if (rawBytes > maxImageBytes) {
    final scale = sqrt(maxImageBytes.toDouble() / rawBytes.toDouble());
    wrapped = image.copyResize(wrapped, width: (img.width * scale).round(), height: (img.height * scale).round(), interpolation: image.Interpolation.cubic);
  }

  final res = image.encodeJpg(wrapped, quality: 70);
  print('encoded ${img.width}x${img.height} image as ${wrapped.width}x${wrapped.height} in ${res.lengthInBytes} bytes');
  return res;
}
