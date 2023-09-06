import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:phone_iot_2/conversions.dart';

import 'ffi.dart';
import 'sensors.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

const double minUpdateIntervalMs = 100;
const int timingEpsilon = 20;
const int defaultServerPort = 1976;
const int defaultClientPort = 6787;
const Duration heartbeatPeriod = Duration(seconds: 30);

bool isIP(String addr) {
  final pat = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
  return pat.firstMatch(addr) != null;
}

class SchedulerEntry {
  int lastUpdateMs;
  int updateIntervalMs;

  SchedulerEntry.fromMs(double ms) : lastUpdateMs = 0, updateIntervalMs = ms.toInt() - timingEpsilon;
  static SchedulerEntry? maybeFromMs(double? ms) => ms != null ? SchedulerEntry.fromMs(ms) : null;

  bool advance(int nowMs) {
    if (nowMs - lastUpdateMs < updateIntervalMs) return false;
    lastUpdateMs = nowMs;
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
  static Scheduler localUpdateScheduler = Scheduler.empty();
  static SchedulerEntry? remoteUpdateScheduler;
  static int remoteUpdateCounter = 0;
  static Timer? sensorUpdateTimer;

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
  static void netsbloxSendSensor(int heading, List<double>? value) {
    final msg = <int>[];
    msg.add(heading);
    for (final x in value ?? <double>[]) {
      msg.addAll(f64ToBEBytes(x));
    }
    netsbloxSend(msg);
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

    if (msg.data[0] == 'a'.codeUnitAt(0)) { // authenticate
      netsbloxSend([ msg.data[0] ]);
    }
    else if (msg.data[0] == 'A'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.accelerometer.value);
    }
    else if (msg.data[0] == 'G'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.gravity.value);
    }
    else if (msg.data[0] == 'L'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.linearAccelerometer.value);
    }
    else if (msg.data[0] == 'Y'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.gyroscope.value);
    }
    else if (msg.data[0] == 'R'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.rotationVector.value);
    }
    else if (msg.data[0] == 'r'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.gameRotationVector.value);
    }
    else if (msg.data[0] == 'M'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.magnetometer.value);
    }
    else if (msg.data[0] == 'm'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.microphone.value);
    }
    else if (msg.data[0] == 'P'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.proximity.value);
    }
    else if (msg.data[0] == 'S'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.stepCount.value);
    }
    else if (msg.data[0] == 'l'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.lightLevel.value);
    }
    else if (msg.data[0] == 'F'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.pressure.value);
    }
    else if (msg.data[0] == 'f'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.temperature.value);
    }
    else if (msg.data[0] == 'K'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.relativeHumidity.value);
    }
    else if (msg.data[0] == 'X'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.gps.value);
    }
    else if (msg.data[0] == 'O'.codeUnitAt(0)) {
      netsbloxSendSensor(msg.data[0], SensorManager.orientation.value);
    }
    else if (msg.data[0] == 'p'.codeUnitAt(0)) { // set sensor packet update intervals
      if (msg.data.length >= 9 && (msg.data.length - 9) % 4 == 0) {
        final vals = <double>[];
        for (int p = 9; p < msg.data.length; p += 4) {
          vals.add(u32FromBEBytes(msg.data.sublist(p, p + 4)).toDouble());
        }
        listenToSensors(null, vals);
        netsbloxSend([ msg.data[0] ]);
      }
    }
    else {
      print('unhandled datagram... ${msg.data}');
    }
  }

  static void listenToSensors(SensorUpdateInfo? newLocalIntervals, List<double>? newRemoteIntervals) {
    sensorUpdateTimer?.cancel();
    sensorUpdateTimer = null;

    final updateIntervals = <double>[];

    final newLocal = newLocalIntervals == null ? localUpdateScheduler : Scheduler.basedOn(newLocalIntervals);
    localUpdateScheduler = newLocal;
    if (newLocal.gravity != null) updateIntervals.add(newLocal.gravity!.updateIntervalMs.toDouble());
    if (newLocal.gyroscope != null) updateIntervals.add(newLocal.gyroscope!.updateIntervalMs.toDouble());
    if (newLocal.orientation != null) updateIntervals.add(newLocal.orientation!.updateIntervalMs.toDouble());
    if (newLocal.accelerometer != null) updateIntervals.add(newLocal.accelerometer!.updateIntervalMs.toDouble());
    if (newLocal.magneticField != null) updateIntervals.add(newLocal.magneticField!.updateIntervalMs.toDouble());
    if (newLocal.linearAccelerometer != null) updateIntervals.add(newLocal.linearAccelerometer!.updateIntervalMs.toDouble());
    if (newLocal.lightLevel != null) updateIntervals.add(newLocal.lightLevel!.updateIntervalMs.toDouble());
    if (newLocal.microphone != null) updateIntervals.add(newLocal.microphone!.updateIntervalMs.toDouble());
    if (newLocal.proximity != null) updateIntervals.add(newLocal.proximity!.updateIntervalMs.toDouble());
    if (newLocal.stepCount != null) updateIntervals.add(newLocal.stepCount!.updateIntervalMs.toDouble());
    if (newLocal.gps != null) updateIntervals.add(newLocal.gps!.updateIntervalMs.toDouble());
    if (newLocal.pressure != null) updateIntervals.add(newLocal.pressure!.updateIntervalMs.toDouble());
    if (newLocal.temperature != null) updateIntervals.add(newLocal.temperature!.updateIntervalMs.toDouble());
    if (newLocal.relativeHumidity != null) updateIntervals.add(newLocal.relativeHumidity!.updateIntervalMs.toDouble());

    final newRemote = newRemoteIntervals == null ? remoteUpdateScheduler : newRemoteIntervals.isEmpty ? null : SchedulerEntry.fromMs(newRemoteIntervals.reduce(min));
    remoteUpdateScheduler = newRemote;
    if (newRemote != null) updateIntervals.add(newRemote.updateIntervalMs.toDouble());

    if (updateIntervals.isNotEmpty) {
      sensorUpdateTimer = Timer.periodic(Duration(milliseconds: max(updateIntervals.reduce(min), minUpdateIntervalMs).toInt()), (timer) => sendUpdate());
    }
  }

  static void sendUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch;

    final accelerometer = SensorManager.accelerometer.value;
    if (accelerometer != null && localUpdateScheduler.accelerometer?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'accelerometer', values: [
        ('x', SimpleValue.number(accelerometer[0])),
        ('y', SimpleValue.number(accelerometer[1])),
        ('z', SimpleValue.number(accelerometer[2])),
        ('facingDir', SimpleValue.string(facingDirectionNames[SensorManager.facingDirection.value![0].toInt()])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final linearAccelerometer = SensorManager.linearAccelerometer.value;
    if (linearAccelerometer != null && localUpdateScheduler.linearAccelerometer?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'linearAcceleration', values: [
        ('x', SimpleValue.number(linearAccelerometer[0])),
        ('y', SimpleValue.number(linearAccelerometer[1])),
        ('z', SimpleValue.number(linearAccelerometer[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gravity = SensorManager.gravity.value;
    if (gravity != null && localUpdateScheduler.gravity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gravity', values: [
        ('x', SimpleValue.number(gravity[0])),
        ('y', SimpleValue.number(gravity[1])),
        ('z', SimpleValue.number(gravity[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final lightLevel = SensorManager.lightLevel.value;
    if (lightLevel != null && localUpdateScheduler.lightLevel?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'lightLevel', values: [
        ('level', SimpleValue.number(lightLevel[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final pressure = SensorManager.pressure.value;
    if (pressure != null && localUpdateScheduler.pressure?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'pressure', values: [
        ('pressure', SimpleValue.number(pressure[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gyroscope = SensorManager.gyroscope.value;
    if (gyroscope != null && localUpdateScheduler.gyroscope?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gyroscope', values: [
        ('x', SimpleValue.number(gyroscope[0])),
        ('y', SimpleValue.number(gyroscope[1])),
        ('z', SimpleValue.number(gyroscope[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final magnetometer = SensorManager.magnetometer.value;
    if (magnetometer != null && localUpdateScheduler.magneticField?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'magneticField', values: [
        ('x', SimpleValue.number(magnetometer[0])),
        ('y', SimpleValue.number(magnetometer[1])),
        ('z', SimpleValue.number(magnetometer[2])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final gps = SensorManager.gps.value;
    if (gps != null && localUpdateScheduler.gps?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'location', values: [
        ('latitude', SimpleValue.number(gps[0])),
        ('longitude', SimpleValue.number(gps[1])),
        ('heading', SimpleValue.number(gps[2])),
        ('altitude', SimpleValue.number(gps[3])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final orientation = SensorManager.orientation.value;
    if (orientation != null && localUpdateScheduler.orientation?.advance(now) == true) {
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
    if (temperature != null && localUpdateScheduler.temperature?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'temperature', values: [
        ('temp', SimpleValue.number(temperature[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final relativeHumidity = SensorManager.relativeHumidity.value;
    if (relativeHumidity != null && localUpdateScheduler.relativeHumidity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'humidity', values: [
        ('relative', SimpleValue.number(relativeHumidity[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final microphone = SensorManager.microphone.value;
    if (microphone != null && localUpdateScheduler.microphone?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'microphoneLevel', values: [
        ('volume', SimpleValue.number(microphone[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final proximity = SensorManager.proximity.value;
    if (proximity != null && localUpdateScheduler.proximity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'proximity', values: [
        ('distance', SimpleValue.number(proximity[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    final stepCount = SensorManager.stepCount.value;
    if (stepCount != null && localUpdateScheduler.stepCount?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'stepCount', values: [
        ('count', SimpleValue.number(stepCount[0])),
        ('device', const SimpleValue.number(0)),
      ]));
    }

    if (remoteUpdateScheduler?.advance(now) == true) {
      final packet = <int>[];
      packet.add('Q'.codeUnitAt(0));
      packet.addAll(u32ToBEBytes(remoteUpdateCounter++));

      final sensors = [
        SensorManager.accelerometer, SensorManager.gravity, SensorManager.linearAccelerometer, SensorManager.gyroscope,
        SensorManager.rotationVector, SensorManager.gameRotationVector, SensorManager.magnetometer,
        SensorManager.microphone, SensorManager.proximity, SensorManager.stepCount, SensorManager.lightLevel,
        SensorManager.gps, SensorManager.orientation, SensorManager.pressure, SensorManager.temperature,
        SensorManager.relativeHumidity,
      ];
      for (final sensor in sensors) {
        final data = sensor.value;
        if (data != null) {
          assert(data.length <= 127);
          packet.add(data.length);
          for (final val in data) {
            packet.addAll(f64ToBEBytes(val));
          }
        } else {
          packet.add(0);
        }
      }

      netsbloxSend(packet);
    }
  }
}
