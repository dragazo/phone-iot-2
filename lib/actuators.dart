import 'dart:math';

import 'package:vibration/vibration.dart';

class VibrationManager {
  static void vibrate(double intensityPercent, List<double> patternSeconds) {
    Vibration.cancel();
    final intensity = (intensityPercent * 255 / 100).round().clamp(0, 255);

    final pattern = [0];
    final intensities = [0];
    for (int i = 0; i < patternSeconds.length; ++i) {
      pattern.add(max(0, (patternSeconds[i] * 1000).round()));
      intensities.add(i & 1 == 0 ? intensity : 0);
    }

    Vibration.vibrate(pattern: pattern, intensities: intensities);
  }
}
