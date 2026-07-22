import 'dart:math';

import 'main.dart';

import 'package:vibration/vibration.dart';

class VibrationManager {
  // pattern is a list of pairs of form (duration in seconds, strength percent)
  static void vibrate(List<(double, double)> pattern) {
    Vibration.cancel();

    final x = <int>[];
    final y = <int>[];
    var sleep = 0;
    for (final v in pattern) {
      final duration = (v.$1 * 1000).round();
      final intensity = (v.$2 * 255 / 100).round().clamp(0, 255);
      if (duration <= 0) continue;

      if (intensity != 0) {
        x.add(sleep);
        x.add(duration);
        y.add(intensity);
        sleep = 0;
      } else {
        sleep += duration;
      }
    }

    if (x.isNotEmpty) {
      Vibration.vibrate(pattern: x, intensities: y);
    }
  }

  static void triggerControlHaptics() {
    if (SettingsMenu.state.controlHaptics) {
      vibrate([(0.1, 10)]);
    }
  }
}
