import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'canvas.dart';

const updateInterval = Duration(milliseconds: 500);

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

class _MyHomePageState extends State<MyHomePage> {
  late String deviceID;
  late String devicePW;

  late Status status;
  late Timer? timer;

  bool menuOpen = true;

  @override
  void initState() {
    super.initState();

    deviceID = 'test id';
    devicePW = 'test pass';

    api.initialize();
    status = const Status(
      messages: [],
      controls: [],
    );

    void update() {
      api.getStatus()
        .then((res) {
          setState(() => status = res);
          timer = Timer(updateInterval, update);
        })
        .catchError((e) {
          debugPrint('update exception: $e');
          timer = Timer(updateInterval, update);
        });
    }
    update();
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

    final messages = <Widget>[];
    for (final item in status.messages) {
      Color color;
      switch (item.$1) {
        case MessageType.Error:
          color = Colors.red;
        case MessageType.Output:
          color = const Color.fromARGB(255, 80, 80, 80);
      }
      messages.add(Container(
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
              item.$2,
              style: const TextStyle(
                color: Color.fromARGB(255, 200, 200, 200),
              ),
            ),
          ),
        ),
      ));
      messages.add(const SizedBox(height: 5));
    }

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () => setState(() => menuOpen ^= true),
          child: const Icon(
            Icons.list,
          )
        ),
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: (e) {
              print('down ${e.pointer}');
            },
            onPointerMove: (e) {
              print('move ${e.pointer}');
            },
            onPointerUp: (e) {
              print('up ${e.pointer}');
            },
            child: CustomPaint(
              painter: ControlsCanvas(status.controls),
              child: Container(),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Column(
              children: messages,
            ),
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

  // https://editor.netsblox.org/?action=present&Username=devinjean&ProjectName=phoneiot-2-test&
  // https://editor.netsblox.org/api/RawPublic?action=present&Username=devinjean&ProjectName=phoneiot-2-test&

  void _loadProject() {
    var url = widget.projectAddr.text;
    final pat = RegExp(r'^.*\b(\w+)\.netsblox\.org/(.*)$');
    final m = pat.firstMatch(url);
    if (m != null) {
      url = 'https://${m.group(1)}.netsblox.org/api/RawPublic/${m.group(2)}';
    }
    http.get(Uri.parse(url))
      .then((res) {
        api.setProject(xml: res.body);
      })
      .catchError((e) {
        print('error fetching project $e');
      });
  }
  void _startProject() {
    api.startProject();
  }
}
