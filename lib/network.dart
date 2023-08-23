import 'dart:async';
import 'dart:math';
import 'ffi.dart';
import 'sensors.dart';

const int timingEpsilon = 20;

class SchedulerEntry {
  int lastUpdate;
  int updateInterval;

  SchedulerEntry.fromMs(double ms) : lastUpdate = 0, updateInterval = ms.toInt() - timingEpsilon;
  static SchedulerEntry? maybeFromMs(double? ms) => ms != null ? SchedulerEntry.fromMs(ms) : null;

  bool advance(int now) {
    if (now - lastUpdate < updateInterval) return false;
    lastUpdate = now;
    return true;
  }
}
class Scheduler {
  SchedulerEntry? accelerometer;

  Scheduler.empty();
  Scheduler.basedOn(SensorUpdateInfo sensors) :
    accelerometer = SchedulerEntry.maybeFromMs(sensors.accelerometer);
}

class NetworkManager {
  static const double minUpdateIntervalMs = 50;
  static Scheduler scheduler = Scheduler.empty();
  static Timer? updateTimer;

  static void listenToSensors(SensorUpdateInfo sensors) {
    scheduler = Scheduler.basedOn(sensors);

    final updateIntervals = <double>[];
    if (sensors.gravity != null) updateIntervals.add(max(sensors.gravity!, minUpdateIntervalMs));
    if (sensors.gyroscope != null) updateIntervals.add(max(sensors.gyroscope!, minUpdateIntervalMs));
    if (sensors.orientation != null) updateIntervals.add(max(sensors.orientation!, minUpdateIntervalMs));
    if (sensors.accelerometer != null) updateIntervals.add(max(sensors.accelerometer!, minUpdateIntervalMs));
    if (sensors.magneticField != null) updateIntervals.add(max(sensors.magneticField!, minUpdateIntervalMs));
    if (sensors.linearAcceleration != null) updateIntervals.add(max(sensors.linearAcceleration!, minUpdateIntervalMs));
    if (sensors.lightLevel != null) updateIntervals.add(max(sensors.lightLevel!, minUpdateIntervalMs));
    if (sensors.microphoneLevel != null) updateIntervals.add(max(sensors.microphoneLevel!, minUpdateIntervalMs));
    if (sensors.proximity != null) updateIntervals.add(max(sensors.proximity!, minUpdateIntervalMs));
    if (sensors.stepCount != null) updateIntervals.add(max(sensors.stepCount!, minUpdateIntervalMs));
    if (sensors.location != null) updateIntervals.add(max(sensors.location!, minUpdateIntervalMs));
    if (sensors.pressure != null) updateIntervals.add(max(sensors.pressure!, minUpdateIntervalMs));
    if (sensors.temperature != null) updateIntervals.add(max(sensors.temperature!, minUpdateIntervalMs));
    if (sensors.humidity != null) updateIntervals.add(max(sensors.humidity!, minUpdateIntervalMs));

    double? minInterval;
    for (final x in updateIntervals) {
      if (minInterval == null || x < minInterval) minInterval = x;
    }
    if (minInterval != null) {
      updateTimer?.cancel();
      updateTimer = Timer.periodic(Duration(milliseconds: minInterval.toInt()), (timer) => sendUpdate());
    }
  }

  static void sendUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch;

    final accelerometer = SensorManager.accelerometer.value;
    if (accelerometer != null && scheduler.accelerometer?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'accelerometer', values: [
        ('x', SimpleValue.number(accelerometer[0])),
        ('y', SimpleValue.number(accelerometer[1])),
        ('z', SimpleValue.number(accelerometer[2])),
        ('facingDir', SimpleValue.string(facingDirectionNames[SensorManager.facingDirection.f([accelerometer])![0].toInt()])),
        ('device', const SimpleValue.number(0)),
      ]));
    }
  }
}
