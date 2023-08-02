import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

List<double> elementwise(List<double> a, List<double> b, double Function (double, double) f) {
  assert (a.length == b.length);

  final res = <double>[];
  for (int i = 0; i < a.length; ++i) {
    res.add(f(a[i], b[i]));
  }
  return res;
}

abstract class Sensor {
  List<double>? get value;
}

class RawSensor<E> extends Sensor {
  @override List<double>? value;
  StreamSubscription<E>? listener;

  void stop() {
    listener?.cancel();
    listener = null;
  }
}

class CalcSensor extends Sensor {
  final List<Sensor> src;
  final List<double> Function(List<List<double>>) f;

  CalcSensor({ required this.src, required this.f });

  @override List<double>? get value {
    final src = <List<double>>[];
    for (final x in this.src) {
      final v = x.value;
      if (v == null) return null;
      src.add(v);
    }
    return f(src);
  }
}

class SensorManager {
  static bool running = false;

  static RawSensor<AccelerometerEvent> accelerometer = RawSensor();
  static RawSensor<UserAccelerometerEvent> linearAccelerometer = RawSensor();
  static RawSensor<GyroscopeEvent> gyroscope = RawSensor();
  static RawSensor<MagnetometerEvent> magnetometer = RawSensor();

  static CalcSensor gravity = CalcSensor(src: [accelerometer, linearAccelerometer], f: (x) => elementwise(x[0], x[1], (a, b) => a - b));

  static void start() {
    if (running) return;
    running = true;

    accelerometer.listener ??= accelerometerEvents.listen((e) => accelerometer.value = [e.x, e.y, e.z]);
    linearAccelerometer.listener ??= userAccelerometerEvents.listen((e) => linearAccelerometer.value = [e.x, e.y, e.z]);
    gyroscope.listener ??= gyroscopeEvents.listen((e) => gyroscope.value = [e.x, e.y, e.z]);
    magnetometer.listener ??= magnetometerEvents.listen((e) => magnetometer.value = [e.x, e.y, e.z]);
  }
  static void stop() {
    if (!running) return;
    running = false;

    accelerometer.stop();
    linearAccelerometer.stop();
    gyroscope.stop();
    magnetometer.stop();
  }
}
