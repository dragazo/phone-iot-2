import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:phone_iot_2/conversions.dart';

import 'ffi.dart';
import 'sensors.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

const int timingEpsilon = 20;
const int defaultServerPort = 1976;
const int defaultClientPort = 6787;
const Duration heartbeatPeriod = Duration(seconds: 30);

bool isIP(String addr) {
  final pat = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
  return pat.firstMatch(addr) != null;
}

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
  SchedulerEntry? linearAccelerometer;
  SchedulerEntry? gravity;
  SchedulerEntry? lightLevel;
  SchedulerEntry? pressure;
  SchedulerEntry? gyroscope;
  SchedulerEntry? magneticField;
  SchedulerEntry? gps;
  SchedulerEntry? orientation;
  SchedulerEntry? temperature;
  SchedulerEntry? relativeHumidity;
  SchedulerEntry? microphone;
  SchedulerEntry? proximity;
  SchedulerEntry? stepCount;

  Scheduler.empty();
  Scheduler.basedOn(SensorUpdateInfo sensors) :
    accelerometer = SchedulerEntry.maybeFromMs(sensors.accelerometer),
    linearAccelerometer = SchedulerEntry.maybeFromMs(sensors.linearAcceleration),
    gravity = SchedulerEntry.maybeFromMs(sensors.gravity),
    lightLevel = SchedulerEntry.maybeFromMs(sensors.lightLevel),
    pressure = SchedulerEntry.maybeFromMs(sensors.pressure),
    gyroscope = SchedulerEntry.maybeFromMs(sensors.gyroscope),
    magneticField = SchedulerEntry.maybeFromMs(sensors.magneticField),
    gps = SchedulerEntry.maybeFromMs(sensors.location),
    orientation = SchedulerEntry.maybeFromMs(sensors.orientation),
    temperature = SchedulerEntry.maybeFromMs(sensors.temperature),
    relativeHumidity = SchedulerEntry.maybeFromMs(sensors.humidity),
    microphone = SchedulerEntry.maybeFromMs(sensors.microphoneLevel),
    proximity = SchedulerEntry.maybeFromMs(sensors.proximity),
    stepCount = SchedulerEntry.maybeFromMs(sensors.stepCount);
}

class NetworkManager {
  static const double minUpdateIntervalMs = 50;
  static Scheduler scheduler = Scheduler.empty();
  static Timer? updateTimer;

  static RawDatagramSocket? udp;
  static InternetAddress? serverAddr;
  static int? serverPort;
  static Timer? heartbeatTimer;

  static void netsbloxSend(List<int> msg) {
    final mac = MainMenu.state.deviceID;
    final addr = serverAddr;
    final port = serverPort;
    if (addr == null || port == null) return;

    final res = <int>[];
    res.addAll(mac);
    res.addAll([0, 0, 0, 0]);
    res.addAll(msg);

    udp?.send(res, addr, port);
  }

  static void disconnect() {
    udp?.close();
    udp = null;

    heartbeatTimer?.cancel();
    heartbeatTimer = null;

    serverPort = null;
    serverAddr = null;
  }
  static Future<void> connect() async {
    try {
      disconnect();

      String addr = MainMenu.serverAddr.text;
      final target = isIP(addr) ? '$addr:8080' : addr.startsWith('https://') ? addr : 'https://$addr';
      final res = await http.get(Uri.parse('$target/services/routes/phone-iot/port'));

      serverPort = int.tryParse(res.body) ?? defaultServerPort;
      serverAddr = (await InternetAddress.lookup(addr))[0];

      final newUdp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, defaultClientPort);
      udp = newUdp;
      newUdp.forEach((e) {
        if (e == RawSocketEvent.read) {
          final msg = newUdp.receive();
          if (msg != null) handleUdpMessage(msg);
        }
      });

      heartbeatTimer = Timer.periodic(heartbeatPeriod, (t) {
        netsbloxSend([ 'I'.codeUnitAt(0) ]);
      });

      netsbloxSend([ 'I'.codeUnitAt(0), 0 ]); // send first heartbeat and add an ACK check flag
    } catch (e) {
      MessageList.state.addMessage(Message('Failed to Connect: $e', MessageType.stderr));
    }
  }
  static void requestConnReset() {
    netsbloxSend([ 'I'.codeUnitAt(0), 86 ]);
  }

  static void handleUdpMessage(Datagram msg) {
    if (msg.data.isEmpty) return;

    // check for things that don't need auth
    if (msg.data.length <= 2 && msg.data[0] == 'I'.codeUnitAt(0)) {
      if (msg.data.length == 1 || (msg.data.length == 2 && msg.data[1] == 1)) {
        MessageList.state.addMessage(Message('Connected to NetsBlox', MessageType.stdout));
        return;
      } else if (msg.data.length == 2 && msg.data[1] == 87) {
        MessageList.state.addMessage(Message('Connection Reset', MessageType.stdout));
        Timer(const Duration(seconds: 3), () => connect());
        return;
      }
    }

    // ignore anything that's invalid or fails to auth
    if (msg.data.length < 9 || u64FromBEBytes(msg.data.sublist(1, 9)) != MainMenu.state.getPassword()) {
      return;
    }

    // authenticate
    if (msg.data[0] == 'a'.codeUnitAt(0)) {
      netsbloxSend([ msg.data[0] ]);
    } else {
      print('unhandled datagram... ${msg.data}');
    }
  }

  static void listenToSensors(SensorUpdateInfo sensors) {
    updateTimer?.cancel();
    updateTimer = null;

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
        ('facingDir', SimpleValue.string(facingDirectionNames[SensorManager.facingDirection.value![0].toInt()])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final linearAccelerometer = SensorManager.linearAccelerometer.value;
    if (linearAccelerometer != null && scheduler.linearAccelerometer?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'linearAcceleration', values: [
        ('x', SimpleValue.number(linearAccelerometer[0])),
        ('y', SimpleValue.number(linearAccelerometer[1])),
        ('z', SimpleValue.number(linearAccelerometer[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gravity = SensorManager.gravity.value;
    if (gravity != null && scheduler.gravity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gravity', values: [
        ('x', SimpleValue.number(gravity[0])),
        ('y', SimpleValue.number(gravity[1])),
        ('z', SimpleValue.number(gravity[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final lightLevel = SensorManager.lightLevel.value;
    if (lightLevel != null && scheduler.lightLevel?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'lightLevel', values: [
        ('level', SimpleValue.number(lightLevel[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final pressure = SensorManager.pressure.value;
    if (pressure != null && scheduler.pressure?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'pressure', values: [
        ('pressure', SimpleValue.number(pressure[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gyroscope = SensorManager.gyroscope.value;
    if (gyroscope != null && scheduler.gyroscope?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gyroscope', values: [
        ('x', SimpleValue.number(gyroscope[0])),
        ('y', SimpleValue.number(gyroscope[1])),
        ('z', SimpleValue.number(gyroscope[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final magnetometer = SensorManager.magnetometer.value;
    if (magnetometer != null && scheduler.magneticField?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'magneticField', values: [
        ('x', SimpleValue.number(magnetometer[0])),
        ('y', SimpleValue.number(magnetometer[1])),
        ('z', SimpleValue.number(magnetometer[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gps = SensorManager.gps.value;
    if (gps != null && scheduler.gps?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'location', values: [
        ('latitude', SimpleValue.number(gps[0])),
        ('longitude', SimpleValue.number(gps[1])),
        ('heading', SimpleValue.number(gps[2])),
        ('altitude', SimpleValue.number(gps[3])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final orientation = SensorManager.orientation.value;
    if (orientation != null && scheduler.orientation?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'orientation', values: [
        ('x', SimpleValue.number(orientation[0])),
        ('y', SimpleValue.number(orientation[1])),
        ('z', SimpleValue.number(orientation[2])),
        ('heading', SimpleValue.number(orientation[0])),
        ('dir', SimpleValue.string(compassDirectionNames[SensorManager.compassDirection.value![0].toInt()])),
        ('cardinalDir', SimpleValue.string(compassCardinalDirectionNames[SensorManager.compassCardinalDirection.value![0].toInt()])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final temperature = SensorManager.temperature.value;
    if (temperature != null && scheduler.temperature?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'temperature', values: [
        ('temp', SimpleValue.number(temperature[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final relativeHumidity = SensorManager.relativeHumidity.value;
    if (relativeHumidity != null && scheduler.relativeHumidity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'humidity', values: [
        ('relative', SimpleValue.number(relativeHumidity[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final microphone = SensorManager.microphone.value;
    if (microphone != null && scheduler.microphone?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'microphoneLevel', values: [
        ('volume', SimpleValue.number(microphone[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final proximity = SensorManager.proximity.value;
    if (proximity != null && scheduler.proximity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'proximity', values: [
        ('distance', SimpleValue.number(proximity[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final stepCount = SensorManager.stepCount.value;
    if (stepCount != null && scheduler.stepCount?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'stepCount', values: [
        ('count', SimpleValue.number(stepCount[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }
  }
}
