import 'dart:math';

import 'main.dart';

import 'package:vibration/vibration.dart';

class VibrationManager {
  // pattern is a list of pairs of form (duration in seconds, strength percent)
  static void vibrate(List<(double, double)> pattern) {
    Vibration.cancel();

    final x = <int>[];
    final y = <int>[];
    for (final v in pattern) {
      x.add(max(0, (v.$1 * 1000).round()));
      y.add((v.$2 * 255 / 100).round().clamp(0, 255));
    }

    Vibration.vibrate(pattern: x, intensities: y);
  }

  static void triggerControlHaptics() {
    if (SettingsMenu.state.controlHaptics) {
      vibrate([(0.1, 10)]);
    }
  }
}
