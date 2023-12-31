import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'actuators.dart';
import 'canvas.dart';
import 'conversions.dart';
import 'util.dart';

import 'ffi.dart';
import 'sensors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fgbg/flutter_fgbg.dart';

import 'main.dart';

const double minUpdateIntervalMs = 100;
const int timingEpsilon = 20;
const int defaultServerPort = 1976;
const int defaultClientPort = 6787;
const Duration heartbeatPeriod = Duration(seconds: 30);

Uint8List? parseIP(String addr) {
  final pat = RegExp(r'^(\w+://)?(\d+\.\d+\.\d+\.\d+)(:\d+)?$');
  final m = pat.firstMatch(addr);
  if (m == null) return null;

  final vals = m.group(2)!.split('.').map(int.tryParse).toList();
  if (vals.length != 4 || vals.any((x) => x == null || x < 0 || x >= 256)) return null;
  return Uint8List.fromList(vals.map((x) => x!).toList());
}
bool hasProtocol(String addr) {
  final pat = RegExp(r'^\w+://');
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
  static StreamSubscription<FGBGType>? fgbgListener;
  static bool running = true;

  static void netsbloxSend(List<int> msg) {
    final mac = MainMenu.state.deviceID;
    final addr = serverAddr;
    final port = serverPort;
    if (addr == null || port == null || !running) return;

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
    fgbgListener ??= FGBGEvents.stream.listen((e) {
      switch (e) {
        case FGBGType.foreground:
          running = true;
          netsbloxSend([ 'I'.codeUnitAt(0), 0 ]); // send heartbeat with ACK request
        case FGBGType.background:
          running = false;
      }
    });

    try {
      disconnect();

      String addr = MainMenu.serverAddr.text;
      Uint8List? ipInfo = parseIP(addr);
      final res = await http.get(Uri.parse('${hasProtocol(addr) ? addr : "https://$addr"}/services/routes/phone-iot/port'));

      serverPort = int.tryParse(res.body) ?? defaultServerPort;
      serverAddr = ipInfo != null ? InternetAddress.fromRawAddress(ipInfo) : (await InternetAddress.lookup(addr))[0];

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

      netsbloxSend([ 'I'.codeUnitAt(0), 0 ]); // send heartbeat with ACK request
    } catch (e) {
      MessageList.state.addMessage(Message('Failed to Connect: $e', MessageType.stderr));
    }
  }
  static void requestConnReset() {
    netsbloxSend([ 'I'.codeUnitAt(0), 86 ]);
  }

  static void handleUdpMessage(Datagram msg) {
    if (msg.data.isEmpty || !running) return;

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
    else if (msg.data[0] == 'C'.codeUnitAt(0)) { // clear controls
      Display.state.clearControls();
      netsbloxSend([ msg.data[0] ]);
    }
    else if (msg.data[0] == 'c'.codeUnitAt(0)) { // remove control
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        Display.state.removeControl(id);
        netsbloxSend([ msg.data[0] ]);
      }
    }
    else if (msg.data[0] == 'H'.codeUnitAt(0)) { // set text
      if (msg.data.length >= 10) {
        final idLen = msg.data[9];
        if (msg.data.length >= 10 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(10, 10 + idLen));
          final text = tryStringFromBytes(msg.data.sublist(10 + idLen));
          if (id != null && text != null) {
            final target = Display.state.findControl<TextLike>(id);
            if (target != null) {
              Display.state.doSetState(() => target.setText(text, UpdateSource.code));
              netsbloxSend([ msg.data[0], 0 ]);
            } else {
              netsbloxSend([ msg.data[0], 3]);
            }
          }
        }
      }
    }
    else if (msg.data[0] == 'h'.codeUnitAt(0)) { // get text
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<TextLike>(id);
        if (target != null) {
          netsbloxSend([ msg.data[0], 0 ] + stringToBEBytes(target.getText()));
        } else {
          netsbloxSend([ msg.data[0] ]);
        }
      }
    }
    else if (msg.data[0] == 'i'.codeUnitAt(0)) { // set image
      if (msg.data.length >= 10) {
        final idLen = msg.data[9];
        if (msg.data.length >= 10 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(10, 10 + idLen));
          if (id != null) {
            final target = Display.state.findControl<ImageLike>(id);
            if (target != null) {
              decodeImage(msg.data.sublist(10 + idLen)).then((img) {
                Display.state.doSetState(() => target.setImage(img, UpdateSource.code));
                netsbloxSend([ msg.data[0], 0 ]);
              });
            } else {
              netsbloxSend([ msg.data[0], 3 ]);
            }
          }
        }
      }
    }
    else if (msg.data[0] == 'u'.codeUnitAt(0)) { // get image
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<ImageLike>(id);
        if (target != null) {
          final img = target.getImage();
          if (img != null) {
            packageImageForUdp(img).then((res) => netsbloxSend([ msg.data[0] ] + res));
          } else {
            netsbloxSend([ msg.data[0] ] + blankImage);
          }
        } else {
          netsbloxSend([ msg.data[0] ]);
        }
      }
    }
    else if (msg.data[0] == 'w'.codeUnitAt(0)) { // set toggle state
      if (msg.data.length >= 10) {
        final state = msg.data[9] != 0;
        final id = tryStringFromBytes(msg.data.sublist(10));
        if (id != null) {
          final target = Display.state.findControl<ToggleLike>(id);
          if (target != null) {
            Display.state.doSetState(() => target.setToggled(state));
            netsbloxSend([ msg.data[0], 0 ]);
          } else {
            netsbloxSend([ msg.data[0], 3 ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'W'.codeUnitAt(0)) { // get toggle state
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<ToggleLike>(id);
        netsbloxSend([ msg.data[0], target == null ? 2 : target.getToggled() ? 1 : 0 ]);
      }
    }
    else if (msg.data[0] == 'V'.codeUnitAt(0)) { // is pushed
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<Pressable>(id);
        netsbloxSend([ msg.data[0], target == null ? 2 : target.isPressed() ? 1 : 0 ]);
      }
    }
    else if (msg.data[0] == 'J'.codeUnitAt(0)) { // get position
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<PositionLike>(id);
        if (target != null) {
          final p = target.getPosition();
          netsbloxSend([ msg.data[0], 1 ] + f32ToBEBytes(p.$1) + f32ToBEBytes(p.$2));
        } else {
          netsbloxSend([ msg.data[0] ]);
        }
      }
    }
    else if (msg.data[0] == 'E'.codeUnitAt(0)) { // get level
      final id = tryStringFromBytes(msg.data.sublist(9));
      if (id != null) {
        final target = Display.state.findControl<LevelLike>(id);
        if (target != null) {
          netsbloxSend([ msg.data[0] ] + f32ToBEBytes(target.getLevel()));
        } else {
          netsbloxSend([ msg.data[0] ]);
        }
      }
    }
    else if (msg.data[0] == 'e'.codeUnitAt(0)) { // set level
      if (msg.data.length >= 13) {
        final level = f32FromBEBytes(msg.data.sublist(9, 13));
        final id = tryStringFromBytes(msg.data.sublist(13));
        if (id != null) {
          final target = Display.state.findControl<LevelLike>(id);
          if (target != null) {
            Display.state.doSetState(() => target.setLevel(level));
            netsbloxSend([ msg.data[0], 0 ]);
          } else {
            netsbloxSend([ msg.data[0], 3 ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'g'.codeUnitAt(0)) { // add label
      if (msg.data.length >= 28) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final color = colorFromBEBytes(msg.data.sublist(17, 21));
        final fontSize = f32FromBEBytes(msg.data.sublist(21, 25));
        final align = textAlignFromBEBytes(msg.data.sublist(25, 26));
        final landscape = msg.data[26] != 0;
        final idLen = msg.data[27];
        if (msg.data.length >= 28 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(28, 28 + idLen));
          final text = tryStringFromBytes(msg.data.sublist(28 + idLen));
          if (id != null && text != null) {
            final info = LabelInfo(id: id, x: x, y: y, color: color, text: text, fontSize: fontSize, align: align, landscape: landscape);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomLabel(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'B'.codeUnitAt(0)) { // add button
      if (msg.data.length >= 40) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final height = f32FromBEBytes(msg.data.sublist(21, 25));
        final backColor = colorFromBEBytes(msg.data.sublist(25, 29));
        final foreColor = colorFromBEBytes(msg.data.sublist(29, 33));
        final fontSize = f32FromBEBytes(msg.data.sublist(33, 37));
        final style = buttonStyleFromBEBytes(msg.data.sublist(37, 38));
        final landscape = msg.data[38] != 0;
        final idLen = msg.data[39];
        if (msg.data.length >= 40 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(40, 40 + idLen));
          final text = tryStringFromBytes(msg.data.sublist(40 + idLen));
          if (id != null && text != null) {
            final info = ButtonInfo(id: id, x: x, y: y, width: width, height: height, backColor: backColor, foreColor: foreColor, text: text, fontSize: fontSize, style: style, landscape: landscape);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomButton(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'T'.codeUnitAt(0)) { // add text field
      if (msg.data.length > 41) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final height = f32FromBEBytes(msg.data.sublist(21, 25));
        final backColor = colorFromBEBytes(msg.data.sublist(25, 29));
        final foreColor = colorFromBEBytes(msg.data.sublist(29, 33));
        final fontSize = f32FromBEBytes(msg.data.sublist(33, 37));
        final align = textAlignFromBEBytes(msg.data.sublist(37, 38));
        final readonly = msg.data[38] != 0;
        final landscape = msg.data[39] != 0;
        final idLen = msg.data[40];
        if (msg.data.length >= 41 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(41, 41 + idLen));
          final text = tryStringFromBytes(msg.data.sublist(41 + idLen));
          if (id != null && text != null) {
            final info = TextFieldInfo(id: id, x: x, y: y, width: width, height: height, backColor: backColor, foreColor: foreColor, text: text, fontSize: fontSize, landscape: landscape, readonly: readonly, align: align);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomTextField(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'U'.codeUnitAt(0)) { // add image display
      if (msg.data.length >= 28) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final height = f32FromBEBytes(msg.data.sublist(21, 25));
        final readonly = msg.data[25] != 0;
        final landscape = msg.data[26] != 0;
        final fit = imageFitFromBEBytes(msg.data.sublist(27, 28));
        if (msg.data.length - 28 <= 255) {
          final id = tryStringFromBytes(msg.data.sublist(28));
          if (id != null) {
            final info = ImageDisplayInfo(id: id, x: x, y: y, width: width, height: height, readonly: readonly, landscape: landscape, fit: fit);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomImageDisplay(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'j'.codeUnitAt(0)) { // add joystick
      if (msg.data.length >= 26) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final color = colorFromBEBytes(msg.data.sublist(21, 25));
        final landscape = msg.data[25] != 0;
        if (msg.data.length - 26 <= 255) {
          final id = tryStringFromBytes(msg.data.sublist(26));
          if (id != null) {
            final info = JoystickInfo(id: id, x: x, y: y, width: width, color: color, landscape: landscape);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomJoystick(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'N'.codeUnitAt(0)) { // add touchpad
      if (msg.data.length >= 31) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final height = f32FromBEBytes(msg.data.sublist(21, 25));
        final color = colorFromBEBytes(msg.data.sublist(25, 29));
        final style = touchpadStyleFromBEBytes(msg.data.sublist(29, 30));
        final landscape = msg.data[30] != 0;
        if (msg.data.length - 31 <= 255) {
          final id = tryStringFromBytes(msg.data.sublist(31));
          if (id != null) {
            final info = TouchpadInfo(id: id, x: x, y: y, width: width, height: height, color: color, style: style, landscape: landscape);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomTouchpad(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'D'.codeUnitAt(0)) { // add slider
      if (msg.data.length >= 32) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final width = f32FromBEBytes(msg.data.sublist(17, 21));
        final color = colorFromBEBytes(msg.data.sublist(21, 25));
        final value = f32FromBEBytes(msg.data.sublist(25, 29));
        final style = sliderStyleFromBEBytes(msg.data.sublist(29, 30));
        final landscape = msg.data[30] != 0;
        final readonly = msg.data[31] != 0;
        if (msg.data.length - 32 <= 255) {
          final id = tryStringFromBytes(msg.data.sublist(32));
          if (id != null) {
            final info = SliderInfo(id: id, x: x, y: y, width: width, color: color, value: value, style: style, landscape: landscape, readonly: readonly);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomSlider(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'Z'.codeUnitAt(0)) { // add toggle
      if (msg.data.length >= 34) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final backColor = colorFromBEBytes(msg.data.sublist(17, 21));
        final foreColor = colorFromBEBytes(msg.data.sublist(21, 25));
        final fontSize = f32FromBEBytes(msg.data.sublist(25, 29));
        final checked = msg.data[29] != 0;
        final style = toggleStyleFromBEBytes(msg.data.sublist(30, 31));
        final landscape = msg.data[31] != 0;
        final readonly = msg.data[32] != 0;
        final idLen = msg.data[33];
        if (msg.data.length >= 34 + idLen) {
          final id = tryStringFromBytes(msg.data.sublist(34, 34 + idLen));
          final text = tryStringFromBytes(msg.data.sublist(34 + idLen));
          if (id != null && text != null) {
            final info = ToggleInfo(id: id, x: x, y: y, text: text, style: style, checked: checked, foreColor: foreColor, backColor: backColor, fontSize: fontSize, landscape: landscape, readonly: readonly);
            netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomToggle(info)).index ]);
          }
        }
      }
    }
    else if (msg.data[0] == 'y'.codeUnitAt(0)) { // add radio button
      if (msg.data.length >= 33) {
        final x = f32FromBEBytes(msg.data.sublist(9, 13));
        final y = f32FromBEBytes(msg.data.sublist(13, 17));
        final backColor = colorFromBEBytes(msg.data.sublist(17, 21));
        final foreColor = colorFromBEBytes(msg.data.sublist(21, 25));
        final fontSize = f32FromBEBytes(msg.data.sublist(25, 29));
        final checked = msg.data[29] != 0;
        final landscape = msg.data[30] != 0;
        final readonly = msg.data[31] != 0;
        final idLen = msg.data[32];
        if (msg.data.length >= 33 + idLen + 1) {
          final id = tryStringFromBytes(msg.data.sublist(33, 33 + idLen));
          final groupLen = msg.data[33 + idLen];
          if (id != null && msg.data.length >= 33 + idLen + 1 + groupLen) {
            final group = tryStringFromBytes(msg.data.sublist(33 + idLen + 1, 33 + idLen + 1 + groupLen));
            final text = tryStringFromBytes(msg.data.sublist(33 + idLen + 1 + groupLen));
            if (group != null && text != null) {
              final info = RadioButtonInfo(id: id, x: x, y: y, text: text, group: group, checked: checked, foreColor: foreColor, backColor: backColor, fontSize: fontSize, landscape: landscape, readonly: readonly);
              netsbloxSend([ msg.data[0], Display.state.tryAddControl(CustomRadioButton(info)).index ]);
            }
          }
        }
      }
    }
    else if (msg.data[0] == 'k'.codeUnitAt(0)) { // vibrate
      if (msg.data.length >= 9 && (msg.data.length - 9) % 8 == 0) {
        final pattern = <(double, double)>[];
        for (int p = 9; p < msg.data.length; p += 8) {
          final duration = f32FromBEBytes(msg.data.sublist(p, p + 4));
          final strength = f32FromBEBytes(msg.data.sublist(p + 4, p + 8));
          pattern.add((duration, strength));
        }
        VibrationManager.vibrate(pattern);
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
    updateIntervals.maybeAddAll([
      newLocal.gravity?.updateIntervalMs.toDouble(),
      newLocal.gyroscope?.updateIntervalMs.toDouble(),
      newLocal.orientation?.updateIntervalMs.toDouble(),
      newLocal.accelerometer?.updateIntervalMs.toDouble(),
      newLocal.magneticField?.updateIntervalMs.toDouble(),
      newLocal.linearAccelerometer?.updateIntervalMs.toDouble(),
      newLocal.lightLevel?.updateIntervalMs.toDouble(),
      newLocal.microphone?.updateIntervalMs.toDouble(),
      newLocal.proximity?.updateIntervalMs.toDouble(),
      newLocal.stepCount?.updateIntervalMs.toDouble(),
      newLocal.gps?.updateIntervalMs.toDouble(),
      newLocal.pressure?.updateIntervalMs.toDouble(),
      newLocal.temperature?.updateIntervalMs.toDouble(),
      newLocal.relativeHumidity?.updateIntervalMs.toDouble(),
    ]);

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
        ('x', DartValue.number(accelerometer[0])),
        ('y', DartValue.number(accelerometer[1])),
        ('z', DartValue.number(accelerometer[2])),
        ('facingDir', DartValue.string(facingDirectionNames[SensorManager.facingDirection.value![0].toInt()])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final linearAccelerometer = SensorManager.linearAccelerometer.value;
    if (linearAccelerometer != null && localUpdateScheduler.linearAccelerometer?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'linearAcceleration', values: [
        ('x', DartValue.number(linearAccelerometer[0])),
        ('y', DartValue.number(linearAccelerometer[1])),
        ('z', DartValue.number(linearAccelerometer[2])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final gravity = SensorManager.gravity.value;
    if (gravity != null && localUpdateScheduler.gravity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gravity', values: [
        ('x', DartValue.number(gravity[0])),
        ('y', DartValue.number(gravity[1])),
        ('z', DartValue.number(gravity[2])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final lightLevel = SensorManager.lightLevel.value;
    if (lightLevel != null && localUpdateScheduler.lightLevel?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'lightLevel', values: [
        ('level', DartValue.number(lightLevel[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final pressure = SensorManager.pressure.value;
    if (pressure != null && localUpdateScheduler.pressure?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'pressure', values: [
        ('pressure', DartValue.number(pressure[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final gyroscope = SensorManager.gyroscope.value;
    if (gyroscope != null && localUpdateScheduler.gyroscope?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'gyroscope', values: [
        ('x', DartValue.number(gyroscope[0])),
        ('y', DartValue.number(gyroscope[1])),
        ('z', DartValue.number(gyroscope[2])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final magnetometer = SensorManager.magnetometer.value;
    if (magnetometer != null && localUpdateScheduler.magneticField?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'magneticField', values: [
        ('x', DartValue.number(magnetometer[0])),
        ('y', DartValue.number(magnetometer[1])),
        ('z', DartValue.number(magnetometer[2])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final gps = SensorManager.gps.value;
    if (gps != null && localUpdateScheduler.gps?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'location', values: [
        ('latitude', DartValue.number(gps[0])),
        ('longitude', DartValue.number(gps[1])),
        ('heading', DartValue.number(gps[2])),
        ('altitude', DartValue.number(gps[3])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final orientation = SensorManager.orientation.value;
    if (orientation != null && localUpdateScheduler.orientation?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'orientation', values: [
        ('x', DartValue.number(orientation[0])),
        ('y', DartValue.number(orientation[1])),
        ('z', DartValue.number(orientation[2])),
        ('heading', DartValue.number(orientation[0])),
        ('dir', DartValue.string(compassDirectionNames[SensorManager.compassDirection.value![0].toInt()])),
        ('cardinalDir', DartValue.string(compassCardinalDirectionNames[SensorManager.compassCardinalDirection.value![0].toInt()])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final temperature = SensorManager.temperature.value;
    if (temperature != null && localUpdateScheduler.temperature?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'temperature', values: [
        ('temp', DartValue.number(temperature[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final relativeHumidity = SensorManager.relativeHumidity.value;
    if (relativeHumidity != null && localUpdateScheduler.relativeHumidity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'humidity', values: [
        ('relative', DartValue.number(relativeHumidity[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final microphone = SensorManager.microphone.value;
    if (microphone != null && localUpdateScheduler.microphone?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'microphoneLevel', values: [
        ('volume', DartValue.number(microphone[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final proximity = SensorManager.proximity.value;
    if (proximity != null && localUpdateScheduler.proximity?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'proximity', values: [
        ('distance', DartValue.number(proximity[0])),
        ('device', const DartValue.number(0)),
      ]));
    }

    final stepCount = SensorManager.stepCount.value;
    if (stepCount != null && localUpdateScheduler.stepCount?.advance(now) == true) {
      api.sendCommand(cmd: RustCommand.injectMessage(msgType: 'stepCount', values: [
        ('count', DartValue.number(stepCount[0])),
        ('device', const DartValue.number(0)),
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
