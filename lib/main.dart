import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import 'sensors.dart';
import 'canvas.dart';

const msgUpdateInterval = Duration(milliseconds: 500);
const msgLifetime = Duration(seconds: 10);

const sensorErrorMsg = 'sensor is not available or is disabled';

const facingDirectionNames = [
  'left', 'vertical', 'up', 'right', 'upside down', 'down',
];
const compassDirectionNames = [
  'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW',
];
const compassCardinalDirectionNames = [
  'N', 'E', 'S', 'W',
];

const passwordLifetime = Duration(hours: 24);

const String kvstoreDeviceID = 'device-id';

late final GetStorage insecureStorage;

String randomHexString(int length) {
  final r = Random();
  final res = StringBuffer();
  const options = '0123456789abcdef';
  for (int i = 0; i < length; ++i) {
    res.writeCharCode(options.codeUnitAt(r.nextInt(options.length)));
  }
  return res.toString();
}

void main() async {
  await GetStorage.init();
  insecureStorage = GetStorage();
  await SensorManager.requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhoneIoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'PhoneIoT-2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final TextEditingController serverAddr = TextEditingController();
  final TextEditingController projectAddr = TextEditingController();
  final TextEditingController textInput = TextEditingController();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum MessageType {
  stdout, stderr,
}
class Message {
  DateTime expiry;
  String msg;
  MessageType type;
  Message(this.msg, this.type) : expiry = DateTime.now().add(msgLifetime);
}

class _MyHomePageState extends State<MyHomePage> {
  late String deviceID;
  late String devicePW;
  late DateTime devicePWExpiry;

  Timer? timer;

  final List<Message> messages = [];
  final LinkedHashMap<String, CustomControl> controls = LinkedHashMap(); // must preserve insertion order iteration
  final Map<int, CustomControl> clickTargets = {};

  bool menuOpen = true;
  TextLike? inputTextTarget;

  @override
  void initState() {
    super.initState();

    if (insecureStorage.hasData(kvstoreDeviceID)) {
      deviceID = insecureStorage.read(kvstoreDeviceID);
    } else {
      deviceID = randomHexString(12);
      insecureStorage.write(kvstoreDeviceID, deviceID);
    }

    devicePW = '00000000';
    devicePWExpiry = DateTime.now().add(passwordLifetime);

    api.initialize(utcOffsetInSeconds: DateTime.now().timeZoneOffset.inSeconds);

    void msgLifetimeUpdateLoop() async {
      while (true) {
        await Future.delayed(msgUpdateInterval);
        final now = DateTime.now();
        while (messages.isNotEmpty && messages.first.expiry.isBefore(now)) {
          setState(() => messages.removeAt(0));
        }
      }
    }
    msgLifetimeUpdateLoop();

    void cmdHandlerLoop() async {
      void sendSensorVec(List<double>? vals, DartRequestKey key) {
        if (vals != null) {
          final res = <SimpleValue>[];
          for (final val in vals) {
            res.add(SimpleValue.number(val));
          }
          api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.list(res)));
        } else {
          api.completeRequest(key: key, result: const RequestResult.err(sensorErrorMsg));
        }
      }
      void sendSensorScalar(List<double>? vals, DartRequestKey key) {
        if (vals != null) {
          assert (vals.length == 1);
          api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.number(vals[0])));
        } else {
          api.completeRequest(key: key, result: const RequestResult.err(sensorErrorMsg));
        }
      }
      void sendSensorScalarEncoded(List<double>? vals, List<String> encoding, DartRequestKey key) {
        if (vals != null) {
          assert (vals.length == 1);
          api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.string(encoding[vals[0].toInt()])));
        } else {
          api.completeRequest(key: key, result: const RequestResult.err(sensorErrorMsg));
        }
      }
      void addControl(CustomControl control, DartRequestKey key) {
        if (controls.containsKey(control.id)) {
          api.completeRequest(key: key, result: RequestResult.err('id ${control.id} is already in use'));
        } else {
          setState(() => controls[control.id] = control);
          api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.string(control.id)));
        }
      }
      T? findControl<T>(String id) {
        CustomControl? x = controls[id];
        return x is T ? x as T : null;
      }
      await for (final cmd in api.recvCommands()) {
        cmd.when(
          stdout: (msg) => setState(() => messages.add(Message(msg, MessageType.stdout))),
          stderr: (msg) => setState(() => messages.add(Message(msg, MessageType.stderr))),

          clearControls: (key) {
            setState(() => controls.clear());
            api.completeRequest(key: key, result: const RequestResult.ok(SimpleValue.string('OK')));
          },
          removeControl: (key, id) {
            setState(() => controls.remove(id));
            api.completeRequest(key: key, result: const RequestResult.ok(SimpleValue.string('OK')));
          },

          addLabel: (key, info) => addControl(CustomLabel(info), key),
          addButton: (key, info) => addControl(CustomButton(info), key),
          addTextField: (key, info) => addControl(CustomTextField(info), key),
          addJoystick: (key, info) => addControl(CustomJoystick(info), key),
          addTouchpad: (key, info) => addControl(CustomTouchpad(info), key),
          addSlider: (key, info) => addControl(CustomSlider(info), key),
          addToggle: (key, info) => addControl(CustomToggle(info), key),
          addImageDisplay: (key, info) => addControl(CustomImageDisplay(info), key),

          getText: (key, id) {
            TextLike? target = findControl<TextLike>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.string(target.getText())) : RequestResult.err('no text-like control with id $id'));
          },
          setText: (key, id, value) {
            TextLike? target = findControl<TextLike>(id);
            if (target != null) setState(() => target.setText(value, UpdateSource.code));
            api.completeRequest(key: key, result: target != null ? const RequestResult.ok(SimpleValue.string('OK')) : RequestResult.err('no text-like control with id $id'));
          },
          isPressed: (key, id) {
            Pressable? target = findControl<Pressable>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.bool(target.isPressed())) : RequestResult.err('no pressable control with id $id'));
          },
          getLevel: (key, id) {
            LevelLike? target = findControl<LevelLike>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.number(target.getLevel())) : RequestResult.err('no level-like control with id $id'));
          },
          setLevel: (key, id, value) {
            LevelLike? target = findControl<LevelLike>(id);
            if (target != null) setState(() => target.setLevel(value));
            api.completeRequest(key: key, result: target != null ? const RequestResult.ok(SimpleValue.string('OK')) : RequestResult.err('no level-like control with id $id'));
          },
          getToggleState: (key, id) {
            ToggleLike? target = findControl<ToggleLike>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.bool(target.getToggled())) : RequestResult.err('no toggle-like control with id $id'));
          },
          setToggleState: (key, id, value) {
            ToggleLike? target = findControl<ToggleLike>(id);
            if (target != null) setState(() => target.setToggled(value));
            api.completeRequest(key: key, result: target != null ? const RequestResult.ok(SimpleValue.string('OK')) : RequestResult.err('no toggle-like control with id $id'));
          },
          getPosition: (key, id) {
            PositionLike? target = findControl<PositionLike>(id);
            if (target != null) {
              final p = target.getPosition();
              api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.list([ SimpleValue.number(p.$1), SimpleValue.number(p.$2) ])));
            } else {
              api.completeRequest(key: key, result: RequestResult.err('no position-like control with id $id'));
            }
          },
          getImage: (key, id) async {
            ImageLike? target = findControl<ImageLike>(id);
            if (target == null) {
              api.completeRequest(key: key, result: RequestResult.err('no image-like control with id $id'));
              return;
            }

            final src = target.getImage()?.clone(); // make sure we have an owning handle for concurrency safety
            try {
              final raw = src != null ? await encodeImage(src) : blankImage;
              api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.image(raw)));
            } catch (e) {
              api.completeRequest(key: key, result: RequestResult.err('failed to encode image: $e'));
            } finally {
              src?.dispose();
            }
          },
          setImage: (key, id, value) async {
            ImageLike? target = findControl<ImageLike>(id);
            if (target == null) {
              api.completeRequest(key: key, result: RequestResult.err('no image-like control with id $id'));
              return;
            }

            try {
              final img = await decodeImage(value);
              setState(() => target.setImage(img, UpdateSource.code));
              api.completeRequest(key: key, result: const RequestResult.ok(SimpleValue.string('OK')));
            } catch (e) {
              api.completeRequest(key: key, result: RequestResult.err('failed to decode image: $e'));
            }
          },

          getAccelerometer: (key) => sendSensorVec(SensorManager.accelerometer.value, key),
          getLinearAccelerometer: (key) => sendSensorVec(SensorManager.linearAccelerometer.value, key),
          getGravity: (key) => sendSensorVec(SensorManager.gravity.value, key),
          getGyroscope: (key) => sendSensorVec(SensorManager.gyroscope.value, key),
          getMagnetometer: (key) => sendSensorVec(SensorManager.magnetometer.value, key),
          getOrientation: (key) => sendSensorVec(SensorManager.orientation.value, key),
          getLocation:(key) => sendSensorVec(SensorManager.locationLatLong.value, key),
          getPressure: (key) => sendSensorScalar(SensorManager.pressure.value, key),
          getRelativeHumidity: (key) => sendSensorScalar(SensorManager.relativeHumidity.value, key),
          getLightLevel: (key) => sendSensorScalar(SensorManager.lightLevel.value, key),
          getTemperature: (key) => sendSensorScalar(SensorManager.temperature.value, key),
          getCompassHeading: (key) => sendSensorScalar(SensorManager.compassHeading.value, key),
          getFacingDirection: (key) => sendSensorScalarEncoded(SensorManager.facingDirection.value, facingDirectionNames, key),
          getCompassDirection: (key) => sendSensorScalarEncoded(SensorManager.compassDirection.value, compassDirectionNames, key),
          getCompassCardinalDirection: (key) => sendSensorScalarEncoded(SensorManager.compassCardinalDirection.value, compassCardinalDirectionNames, key),
        );
      }
    }
    cmdHandlerLoop();

    SensorManager.start();
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    SensorManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    const haloDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 10,
        ),
      ],
    );

    final menu = Container(
      decoration: haloDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/images/AppIcon-512-trans.png', height: 60, isAntiAlias: true),
            Text(widget.title, style: theme.headlineSmall),
            const SizedBox(height: 10),
            Text('Device ID: $deviceID'),
            Text('Password: $devicePW'),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextFormField(
                controller: widget.serverAddr,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  alignLabelWithHint: true,
                  labelText: 'Server Address',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _connect,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _reconnect,
                  child: const Text('Reconnect'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _newPassword,
              child: const Text('New Password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextFormField(
                controller: widget.projectAddr,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  alignLabelWithHint: true,
                  labelText: 'Project Address',
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadProject,
              child: const Text('Load Project'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startProject,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopProject,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final msgs = <Widget>[];
    for (final item in messages) {
      Color color;
      switch (item.type) {
        case MessageType.stderr: color = Colors.red;
        case MessageType.stdout: color = const Color.fromARGB(255, 80, 80, 80);
      }
      msgs.add(Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: color,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 300,
            child: Text(
              item.msg,
              style: const TextStyle(
                color: Color.fromARGB(255, 230, 230, 230),
              ),
            ),
          ),
        ),
      ));
      msgs.add(const SizedBox(height: 5));
    }

    final textInput = Container(
      decoration: haloDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 250,
              height: 150,
              child: TextFormField(
                controller: widget.textInput,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                InkWell(
                  onTap: () {
                    if (inputTextTarget == null) return;
                    inputTextTarget!.setText(widget.textInput.text, UpdateSource.user);
                    setState(() => inputTextTarget = null);
                  },
                  child: const Icon(Icons.check),
                ),
                const SizedBox(height: 30),
                InkWell(
                  onTap: () => setState(() => inputTextTarget = null),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () => setState(() => menuOpen ^= true),
          child: const Icon(Icons.list),
        ),
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: (e) => _handleClick(e.localPosition, e.pointer, ClickType.down),
            onPointerMove: (e) => _handleClick(e.localPosition, e.pointer, ClickType.move),
            onPointerUp: (e) => _handleClick(e.localPosition, e.pointer, ClickType.up),
            child: CustomPaint(
              painter: ControlsCanvas(controls),
              child: Container(),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Column(children: msgs),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: 0,
            right: 0,
            bottom: inputTextTarget != null ? 20 : -200,
            curve: Curves.ease,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [textInput],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: menuOpen ? 20 : -300,
            top: 20,
            curve: Curves.ease,
            child: menu,
          ),
        ],
      ),
    );
  }

  void _connect() {
    print('connect ${widget.serverAddr.text}');
  }
  void _reconnect() {
    print('reconnect ${widget.serverAddr.text}');
  }

  void _newPassword() {
    print('new password');
  }

  void _loadProject() {
    var url = widget.projectAddr.text;
    final pat = RegExp(r'^.*\b(\w+)\.netsblox\.org/(.*)$');
    final m = pat.firstMatch(url);
    if (m != null) {
      url = 'https://${m.group(1)}.netsblox.org/api/RawPublic/${m.group(2)}';
    }
    http.get(Uri.parse(url))
      .then((res) {
        api.sendCommand(cmd: RustCommand.setProject(xml: res.body));
      })
      .catchError((e) {
        setState(() => messages.add(Message('error fetching project $e', MessageType.stderr)));
      });
  }
  void _startProject() {
    api.sendCommand(cmd: const RustCommand.start());
  }
  void _stopProject() {
    api.sendCommand(cmd: const RustCommand.stop());
  }

  void _handleClick(Offset pos, int id, ClickType type) {
    CustomControl? target = clickTargets[id];
    if (target == null && type == ClickType.down) {
      for (final x in controls.values) {
        if (x.contains(pos)) target = x; // don't break, cause we need the last hit on highest layer (no reversed iterator, sadly)
      }
      if (clickTargets.containsValue(target)) return; // don't allow multiple simultaneous touches on the same control
    }
    if (target == null) return;

    switch (type) {
      case ClickType.down: clickTargets[id] = target;
      case ClickType.up: clickTargets.remove(id);
      case ClickType.move: ();
    }
    switch (target.handleClick(pos, type)) {
      case ClickResult.none: ();
      case ClickResult.redraw: setState(() {});
      case ClickResult.requestText:
        inputTextTarget = target as TextLike;
        widget.textInput.text = inputTextTarget!.getText();
        setState(() {});
      case ClickResult.requestImage:
        setState(() => messages.add(Message('requested image - NOT YET SUPPORTED', MessageType.stderr)));
    }
  }
}
