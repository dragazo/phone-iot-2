import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class Sensor<E, T> {
  T? value;
  StreamSubscription<E>? listener;

  void stop() {
    listener?.cancel();
    listener = null;
  }
}

class SensorManager {
  static bool running = false;

  static Sensor<AccelerometerEvent, (double, double, double)> accelerometer = Sensor();
  static Sensor<UserAccelerometerEvent, (double, double, double)> linearAccelerometer = Sensor();
  static Sensor<GyroscopeEvent, (double, double, double)> gyroscope = Sensor();
  static Sensor<MagnetometerEvent, (double, double, double)> magnetometer = Sensor();

  static void start() {
    if (running) return;
    running = true;

    accelerometer.listener ??= accelerometerEvents.listen((e) => accelerometer.value = (e.x, e.y, e.z));
    linearAccelerometer.listener ??= userAccelerometerEvents.listen((e) => linearAccelerometer.value = (e.x, e.y, e.z));
    gyroscope.listener ??= gyroscopeEvents.listen((e) => gyroscope.value = (e.x, e.y, e.z));
    magnetometer.listener ??= magnetometerEvents.listen((e) => magnetometer.value = (e.x, e.y, e.z));
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
