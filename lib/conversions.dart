import 'dart:typed_data';

int u64FromBEBytes(Uint8List src) {
  assert(src.length == 8);
  return ByteData.view(src.buffer).getUint64(0, Endian.big);
}
int u32FromBEBytes(Uint8List src) {
  assert(src.length == 4);
  return ByteData.view(src.buffer).getUint32(0, Endian.big);
}

Uint8List f64ToBEBytes(double src) {
  final res = Uint8List(8);
  ByteData.view(res.buffer).setFloat64(0, src, Endian.big);
  return res;
}
Uint8List u32ToBEBytes(int src) {
  final res = Uint8List(4);
  ByteData.view(res.buffer).setUint32(0, src, Endian.big);
  return res;
}
