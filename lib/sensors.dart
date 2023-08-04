import 'package:environment_sensors/environment_sensors.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:math';

const double radToDeg = 180 / pi;

// annoyingly, some of our sensor deps have platform-dependent units
final double pressureScale = Platform.isAndroid ? 0.1 : 1;

const List<(List<double>, double)> facingDirectionClasses = [
  ([1, 0, 0], 0),
  ([0, 1, 0], 1),
  ([0, 0, 1], 2),
  ([-1, 0, 0], 3),
  ([0, -1, 0], 4),
  ([0, 0, -1], 5),
];
const List<(double, double)> compassDirectionClasses = [
  (0, 0),
  (45, 1),
  (90, 2),
  (135, 3),
  (180, 4),
  (-180, 4),
  (-135, 5),
  (-90, 6),
  (-45, 7),
];
const List<(double, double)> compassCardinalDirectionClasses = [
  (0, 0),
  (90, 1),
  (180, 2),
  (-180, 2),
  (-90, 3),
];

List<double> elementwise(List<double> a, List<double> b, double Function (double, double) f) {
  assert (a.length == b.length);

  final res = <double>[];
  for (int i = 0; i < a.length; ++i) {
    res.add(f(a[i], b[i]));
  }
  return res;
}

double dotProduct(List<double> a, List<double> b) {
  assert (a.length == b.length);

  double res = 0;
  for (int i = 0; i < a.length; ++i) {
    res += a[i] * b[i];
  }
  return res;
}

T dotProductClassify<T>(List<double> v, List<(List<double>, T)> classes) {
  var best = (double.negativeInfinity, -1);
  for (int i = 0; i < classes.length; ++i) {
    double sim = dotProduct(v, classes[i].$1);
    if (sim > best.$1) {
      best = (sim, i);
    }
  }
  return classes[best.$2].$2;
}

T closestClassify<T>(double v, List<(double, T)> classes) {
  var best = (double.infinity, -1);
  for (int i = 0; i < classes.length; ++i) {
    double dist = (v - classes[i].$1).abs();
    if (dist < best.$1) {
      best = (dist, i);
    }
  }
  return classes[best.$2].$2;
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
  final List<double>? Function(List<List<double>>) f;

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
  static RawSensor<AbsoluteOrientationEvent> orientation = RawSensor();
  static RawSensor<Position> gps = RawSensor();
  static RawSensor<double> pressure = RawSensor();
  static RawSensor<double> relativeHumidity = RawSensor();
  static RawSensor<double> lightLevel = RawSensor();
  static RawSensor<double> temperature = RawSensor();

  static CalcSensor gravity = CalcSensor(src: [accelerometer, linearAccelerometer], f: (x) => elementwise(x[0], x[1], (a, b) => a - b));
  static CalcSensor facingDirection = CalcSensor(src: [accelerometer], f: (x) => [dotProductClassify(x[0], facingDirectionClasses)]);
  static CalcSensor compassHeading = CalcSensor(src: [orientation], f: (x) => [x[0][0]]);
  static CalcSensor compassDirection = CalcSensor(src: [orientation], f: (x) => [closestClassify(x[0][0], compassDirectionClasses)]);
  static CalcSensor compassCardinalDirection = CalcSensor(src: [orientation], f: (x) => [closestClassify(x[0][0], compassCardinalDirectionClasses)]);
  static CalcSensor locationLatLong = CalcSensor(src: [gps], f: (x) => [x[0][0], x[0][1]]);
  static CalcSensor locationHeading = CalcSensor(src: [gps], f: (x) => x[0][2] != 0 ? [x[0][2]] : null);
  static CalcSensor locationAltitude = CalcSensor(src: [gps], f: (x) => x[0][3] != 0 ? [x[0][3]] : null);

  static Future<void> requestPermissions() async {
    await Geolocator.requestPermission();
  }

  static void start() {
    if (running) return;
    running = true;

    final envSensors = EnvironmentSensors();

    accelerometer.listener ??= motionSensors.accelerometer.listen((e) => accelerometer.value = [e.x, e.y, e.z]);
    linearAccelerometer.listener ??= motionSensors.userAccelerometer.listen((e) => linearAccelerometer.value = [e.x, e.y, e.z]);
    gyroscope.listener ??= motionSensors.gyroscope.listen((e) => gyroscope.value = [e.x * radToDeg, e.y * radToDeg, e.z * radToDeg]);
    magnetometer.listener ??= motionSensors.magnetometer.listen((e) => magnetometer.value = [e.x, e.y, e.z]);
    pressure.listener ??= envSensors.pressure.listen((e) => pressure.value = [e * pressureScale]);
    gps.listener ??= Geolocator.getPositionStream().listen((e) => gps.value = [e.latitude, e.longitude, e.heading, e.altitude]);
    relativeHumidity.listener ??= envSensors.humidity.listen((e) => relativeHumidity.value = [e]);
    lightLevel.listener ??= envSensors.light.listen((e) => lightLevel.value = [e]);
    temperature.listener ??= envSensors.temperature.listen((e) => temperature.value = [e]);
    orientation.listener ??= motionSensors.absoluteOrientation.listen((e) => orientation.value = [-e.yaw * radToDeg, e.pitch * radToDeg, e.roll * radToDeg]);
  }
  static void stop() {
    if (!running) return;
    running = false;

    accelerometer.stop();
    linearAccelerometer.stop();
    gyroscope.stop();
    magnetometer.stop();
    pressure.stop();
    gps.stop();
    relativeHumidity.stop();
    lightLevel.stop();
    temperature.stop();
    orientation.stop();
  }
}
