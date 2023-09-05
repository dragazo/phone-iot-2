import 'dart:typed_data';

int u64FromBEBytes(Uint8List src) {
  assert(src.length == 8);
  return ByteData.view(src.buffer).getUint64(0, Endian.big);
}

Uint8List f64ToBEBytes(double src) {
  final res = Uint8List(8);
  ByteData.view(res.buffer).setFloat64(0, src, Endian.big);
  return res;
}
