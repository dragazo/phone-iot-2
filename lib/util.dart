extension MaybeAdd<T> on List<T> {
  void maybeAdd(T? val) {
    if (val != null) {
      add(val);
    }
  }
  void maybeAddAll(Iterable<T?> vals) {
    for (final val in vals) {
      maybeAdd(val);
    }
  }
}
