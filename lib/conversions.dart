import 'dart:typed_data';

int u64FromBEBytes(Uint8List src) {
  assert(src.length == 8);
  int res = 0;
  for (final x in src) {
    res = (res << 8) | x;
  }
  return res;
}
