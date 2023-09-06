import 'dart:convert';
import 'dart:typed_data';

import 'package:phone_iot_2/ffi.dart';

String? tryStringFromBytes(Uint8List src) {
  try {
    return utf8.decode(src);
  } catch (e) {
    return null;
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
ColorInfo colorFromBEBytes(Uint8List src) {
  assert(src.length == 4);
  return ColorInfo(a: src[0], r: src[1], g: src[2], b: src[3]);
}
TextAlignInfo alignFromBEBytes(Uint8List src) {
  assert(src.length == 1);
  switch (src[0]) {
    case 1: return TextAlignInfo.Center;
    case 2: return TextAlignInfo.Right;
    default: return TextAlignInfo.Left;
  }
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
