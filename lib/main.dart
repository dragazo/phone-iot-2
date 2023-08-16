import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'sensors.dart';
import 'canvas.dart';

const sensorErrorMsg = 'sensor is not available or is disabled';
const kvstoreDeviceID = 'device-id';

const msgUpdateInterval = Duration(milliseconds: 500);
const msgLifetime = Duration(seconds: 10);
const passwordLifetime = Duration(hours: 24);

const facingDirectionNames = [ 'left', 'vertical', 'up', 'right', 'upside down', 'down' ];
const compassDirectionNames = [ 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' ];
const compassCardinalDirectionNames = [ 'N', 'E', 'S', 'W' ];

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

enum MessageType {
  stdout, stderr,
}
class Message {
  DateTime expiry;
  String msg;
  MessageType type;
  Message(this.msg, this.type) : expiry = DateTime.now().add(msgLifetime);
}

void main() async {
  await GetStorage.init();
  insecureStorage = GetStorage();
  if (Platform.isAndroid || Platform.isIOS) {
    await SensorManager.requestPermissions();
  }
  runApp(App.instance);
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  static const instance = App();

  static const name = 'PhoneIoT-2';
  static const haloDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    color: Colors.white,
    boxShadow: [ BoxShadow(color: Colors.black45, blurRadius: 10) ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhoneIoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen.instance,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  static const instance = MainScreen();
  static final state = MainScreenState();

  @override
  State<MainScreen> createState() => state;
}
class MainScreenState extends State<MainScreen> {
  bool menuOpen = true;
  TextLike? inputTextTarget;
  ImageLike? inputImageTarget;

  @override
  void initState() {
    super.initState();

    api.initialize(utcOffsetInSeconds: DateTime.now().timeZoneOffset.inSeconds);

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
          api.completeRequest(key: key, result: Display.state.tryAddControl(control) ? RequestResult.ok(SimpleValue.string(control.id)) : RequestResult.err('id ${control.id} is already in use'));
      }
      T? findControl<T>(String id) {
        CustomControl? x = Display.state.controls[id];
        return x is T ? x as T : null;
      }
      await for (final cmd in api.recvCommands()) {
        cmd.when(
          stdout: (msg) => MessageList.state.addMessage(Message(msg, MessageType.stdout)),
          stderr: (msg) => MessageList.state.addMessage(Message(msg, MessageType.stderr)),

          clearControls: (key) {
            Display.state.clearControls();
            api.completeRequest(key: key, result: const RequestResult.ok(SimpleValue.string('OK')));
          },
          removeControl: (key, id) {
            Display.state.removeControl(id);
            api.completeRequest(key: key, result: const RequestResult.ok(SimpleValue.string('OK')));
          },

          addLabel: (key, info) => addControl(CustomLabel(info), key),
          addButton: (key, info) => addControl(CustomButton(info), key),
          addTextField: (key, info) => addControl(CustomTextField(info), key),
          addJoystick: (key, info) => addControl(CustomJoystick(info), key),
          addTouchpad: (key, info) => addControl(CustomTouchpad(info), key),
          addSlider: (key, info) => addControl(CustomSlider(info), key),
          addToggle: (key, info) => addControl(CustomToggle(info), key),
          addRadioButton: (key, info) => addControl(CustomRadioButton(info), key),
          addImageDisplay: (key, info) => addControl(CustomImageDisplay(info), key),

          getText: (key, id) {
            TextLike? target = findControl<TextLike>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.string(target.getText())) : RequestResult.err('no text-like control with id $id'));
          },
          setText: (key, id, value) {
            TextLike? target = findControl<TextLike>(id);
            if (target != null) Display.state.setState(() => target.setText(value, UpdateSource.code));
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
            if (target != null) Display.state.setState(() => target.setLevel(value));
            api.completeRequest(key: key, result: target != null ? const RequestResult.ok(SimpleValue.string('OK')) : RequestResult.err('no level-like control with id $id'));
          },
          getToggleState: (key, id) {
            ToggleLike? target = findControl<ToggleLike>(id);
            api.completeRequest(key: key, result: target != null ? RequestResult.ok(SimpleValue.bool(target.getToggled())) : RequestResult.err('no toggle-like control with id $id'));
          },
          setToggleState: (key, id, value) {
            ToggleLike? target = findControl<ToggleLike>(id);
            if (target != null) Display.state.setState(() => target.setToggled(value));
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
              Display.state.setState(() => target.setImage(img, UpdateSource.code));
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
          getLocationLatLong: (key) => sendSensorVec(SensorManager.locationLatLong.value, key),
          getLocationHeading: (key) => sendSensorScalar(SensorManager.locationHeading.value, key),
          getLocationAltitude: (key) => sendSensorScalar(SensorManager.locationAltitude.value, key),
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
    SensorManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () => setState(() => menuOpen ^= true),
          child: const Icon(Icons.list),
        ),
        title: const Text(App.name),
      ),
      body: Stack(
        children: [
          Display.instance,
          const Positioned(
            right: 20,
            top: 20,
            child: MessageList.instance,
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: 0,
            right: 0,
            bottom: inputTextTarget != null ? 20 : -200,
            curve: Curves.ease,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [TextInput.instance],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: 0,
            right: 0,
            bottom: inputImageTarget != null ? 20 : -200,
            curve: Curves.ease,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ImageInput.instance],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            left: menuOpen ? 20 : -300,
            top: 20,
            curve: Curves.ease,
            child: MainMenu.instance,
          ),
        ],
      ),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  static const instance = MainMenu();
  static final state = MainMenuState();

  static final TextEditingController serverAddr = TextEditingController();
  static final TextEditingController projectAddr = TextEditingController();

  @override
  State<MainMenu> createState() => state;
}
class MainMenuState extends State<MainMenu> {
  late String deviceID;
  late String devicePW;
  late DateTime devicePWExpiry;

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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: App.haloDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/images/AppIcon-512-trans.png', height: 60, isAntiAlias: true),
            const Text(App.name, style: TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Text('Device ID: $deviceID'),
            Text('Password: $devicePW'),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextFormField(
                controller: MainMenu.serverAddr,
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
                  onPressed: () => print('connect ${MainMenu.serverAddr.text}'),
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => print('reconnect ${MainMenu.serverAddr.text}'),
                  child: const Text('Reconnect'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => print('new password'),
              child: const Text('New Password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextFormField(
                controller: MainMenu.projectAddr,
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
              onPressed: () {
                var url = MainMenu.projectAddr.text;
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
                    MessageList.state.addMessage(Message('error fetching project $e', MessageType.stderr));
                  });
              },
              child: const Text('Load Project'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => api.sendCommand(cmd: const RustCommand.start()),
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => api.sendCommand(cmd: const RustCommand.stop()),
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);

  static const instance = MessageList();
  static final state = MessageListState();

  @override
  State<MessageList> createState() => state;
}
class MessageListState extends State<MessageList> {
  final messages = <Message>[];

  @override
  void initState() {
    super.initState();

    void updateLoop() async {
      while (true) {
        await Future.delayed(msgUpdateInterval);
        final now = DateTime.now();
        while (messages.isNotEmpty && messages.first.expiry.isBefore(now)) {
          setState(() => messages.removeAt(0));
        }
      }
    }
    updateLoop();
  }

  @override
  Widget build(BuildContext context) {
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

    return Column(children: msgs);
  }

  void addMessage(Message msg) {
    setState(() => messages.add(msg));
  }
}

class Display extends StatefulWidget {
  const Display({Key? key}) : super(key: key);

  static const instance = Display();
  static final state = DisplayState();

  @override
  State<Display> createState() => state;
}
class DisplayState extends State<Display> {
  final LinkedHashMap<String, CustomControl> controls = LinkedHashMap(); // must preserve insertion order iteration
  final Map<int, CustomControl> clickTargets = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => handleClick(e.localPosition, e.pointer, ClickType.down),
      onPointerMove: (e) => handleClick(e.localPosition, e.pointer, ClickType.move),
      onPointerUp: (e) => handleClick(e.localPosition, e.pointer, ClickType.up),
      child: CustomPaint(
        painter: ControlsCanvas(controls),
        child: Container(),
      ),
    );
  }

  bool tryAddControl(CustomControl control) {
    if (controls.containsKey(control.id)) return false;
    setState(() => controls[control.id] = control);
    return true;
  }
  void removeControl(String id) {
    setState(() => controls.remove(id));
  }
  void clearControls() {
    setState(() => controls.clear());
  }

  void handleClick(Offset pos, int id, ClickType type) {
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
      case ClickResult.requestText: MainScreen.state.setState(() => TextInput.controller.text = (MainScreen.state.inputTextTarget = target as TextLike).getText());
      case ClickResult.requestImage: MainScreen.state.setState(() => MainScreen.state.inputImageTarget = target as ImageLike);
      case ClickResult.untoggleOthersInGroup: setState(() {
        final g = (target as GroupLike).getGroup();
        for (final control in controls.values) {
          if (control != target && (control is GroupLike) && (control is ToggleLike) && (control as GroupLike).getGroup() == g) {
            (control as ToggleLike).setToggled(false);
          }
        }
      });
    }
  }
}

class TextInput extends StatefulWidget {
  const TextInput({Key? key}) : super(key: key);

  static const instance = TextInput();
  static final state = TextInputState();

  static final controller = TextEditingController();

  @override
  State<TextInput> createState() => state;
}
class TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: App.haloDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 250,
              height: 150,
              child: TextFormField(
                controller: TextInput.controller,
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                InkWell(
                  onTap: () {
                    Display.state.setState(() => MainScreen.state.inputTextTarget?.setText(TextInput.controller.text, UpdateSource.user));
                    MainScreen.state.setState(() => MainScreen.state.inputTextTarget = null);
                  },
                  child: const Icon(Icons.check),
                ),
                const SizedBox(height: 30),
                InkWell(
                  onTap: () => MainScreen.state.setState(() => MainScreen.state.inputTextTarget = null),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ImageInput extends StatefulWidget {
  const ImageInput({Key? key}) : super(key: key);

  static const instance = ImageInput();
  static final state = ImageInputState();

  @override
  State<ImageInput> createState() => state;
}
class ImageInputState extends State<ImageInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: App.haloDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Select an Image', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              children: [
                InkWell(
                  onTap: () => fetchImage(ImageSource.gallery),
                  child: const Icon(Icons.image, size: 64, color: Colors.blue),
                ),
                const SizedBox(width: 20),
                InkWell(
                  onTap: () => fetchImage(ImageSource.camera),
                  child: const Icon(Icons.photo_camera, size: 64, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => MainScreen.state.setState(() => MainScreen.state.inputImageTarget = null),
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  void fetchImage(ImageSource source) {
    ImageLike? target = MainScreen.state.inputImageTarget;
    if (target == null) return;

    MainScreen.state.setState(() => MainScreen.state.inputImageTarget = null);
    ImagePicker().pickImage(source: source).then((img) {
      if (img != null) img.readAsBytes().then(decodeImage).then((img) => Display.state.setState(() => target.setImage(img, UpdateSource.user)));
    });
  }
}
