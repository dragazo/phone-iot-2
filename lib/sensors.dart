import 'package:sensors_plus/sensors_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:math';

const double radToDeg = 180 / pi;

// annoyingly, some of our sensor deps have platform-dependent units
final double pressureScale = Platform.isAndroid ? 0.1 : 1;

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
  static RawSensor<double> pressure = RawSensor();
  static RawSensor<double> relativeHumidity = RawSensor();

  static CalcSensor gravity = CalcSensor(src: [accelerometer, linearAccelerometer], f: (x) => elementwise(x[0], x[1], (a, b) => a - b));

  static void start() {
    if (running) return;
    running = true;

    final envSensors = EnvironmentSensors();

    accelerometer.listener ??= accelerometerEvents.listen((e) => accelerometer.value = [e.x, e.y, e.z]);
    linearAccelerometer.listener ??= userAccelerometerEvents.listen((e) => linearAccelerometer.value = [e.x, e.y, e.z]);
    gyroscope.listener ??= gyroscopeEvents.listen((e) => gyroscope.value = [e.x * radToDeg, e.y * radToDeg, e.z * radToDeg]);
    magnetometer.listener ??= magnetometerEvents.listen((e) => magnetometer.value = [e.x, e.y, e.z]);
    pressure.listener ??= envSensors.pressure.listen((e) => pressure.value = [e * pressureScale]);
    relativeHumidity.listener ??= envSensors.humidity.listen((e) => relativeHumidity.value = [e]);
  }
  static void stop() {
    if (!running) return;
    running = false;

    accelerometer.stop();
    linearAccelerometer.stop();
    gyroscope.stop();
    magnetometer.stop();
    pressure.stop();
    relativeHumidity.stop();
  }
}
