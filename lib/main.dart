import 'dart:collection';

import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'canvas.dart';

const updateInterval = Duration(milliseconds: 500);
const messageLifetime = Duration(seconds: 10);

void main() {
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
      home: MyHomePage(title: 'PhoneIoT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final TextEditingController serverAddr = TextEditingController();
  final TextEditingController projectAddr = TextEditingController();

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
  Message(this.msg, this.type) : expiry = DateTime.now().add(messageLifetime);
}

class _MyHomePageState extends State<MyHomePage> {
  late String deviceID;
  late String devicePW;
  Timer? timer;

  final List<Message> messages = [];
  final LinkedHashMap<String, CustomControl> controls = LinkedHashMap(); // must preserve insertion order iteration
  final Map<int, CustomControl> clickTargets = {};
  bool menuOpen = true;

  @override
  void initState() {
    super.initState();

    deviceID = 'test id';
    devicePW = 'test pass';

    api.initialize();

    void msgLifetimeUpdateLoop() async {
      while (true) {
        await Future.delayed(const Duration(milliseconds: 500));
        final now = DateTime.now();
        while (messages.isNotEmpty && messages.first.expiry.isBefore(now)) {
          setState(() => messages.removeAt(0));
        }
      }
    }
    msgLifetimeUpdateLoop();

    void cmdHandlerLoop() async {
      void addControl(String id, CustomControl control, DartRequestKey key) {
        if (controls.containsKey(id)) {
          api.completeRequest(key: key, result: RequestResult.err('id $id is already in use'));
        } else {
          setState(() => controls[id] = control);
          api.completeRequest(key: key, result: RequestResult.ok(SimpleValue.string(id)));
        }
      }
      await for (final cmd in api.recvCommands()) {
        cmd.when(
          stdout: (msg) => setState(() => messages.add(Message(msg, MessageType.stdout))),
          stderr: (msg) => setState(() => messages.add(Message(msg, MessageType.stderr))),
          clearControls:() => setState(() => controls.clear()),
          addButton: (info, key) => addControl(info.id, CustomButton(info), key),
          addLabel: (info, key) => addControl(info.id, CustomLabel(info), key),
        );
      }
    }
    cmdHandlerLoop();
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    final menu = Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
          ),
        ],
      ),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Connect'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _reconnect,
              child: const Text('Reconnect'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _newPassword,
              child: const Text('New Password'),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProject,
              child: const Text('Load Project'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _startProject,
              child: const Text('Start'),
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
            duration: const Duration(milliseconds: 10000),
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
        print('error fetching project $e');
      });
  }
  void _startProject() {
    api.sendCommand(cmd: const RustCommand.start());
  }

  void _handleClick(Offset pos, int id, ClickType type) {
    CustomControl? target = clickTargets[id];
    if (target == null && type == ClickType.down) {
      for (final x in controls.values) {
        if (x.contains(pos)) target = x; // don't break, cause we need the last hit on highest layer (no reversed iterator, sadly)
      }
    }
    if (target == null) return;
    switch (type) {
      case ClickType.down: clickTargets[id] = target;
      case ClickType.up: clickTargets.remove(id);
      case ClickType.move: ();
    }
    switch (target.handleClick(pos, type)) {
      case ClickResult.redraw: setState(() {});
      case ClickResult.noRedraw: ();
    }
  }
}
