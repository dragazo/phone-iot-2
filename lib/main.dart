import 'package:flutter/material.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:async';

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
    status = const Status(errors: []);

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
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _newPassword,
              child: const Text('New Password'),
            ),
          ],
        ),
      ),
    );

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
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("NetsBlox VM", style: theme.headlineMedium),
                  Text('errors: ${status.errors}', style: theme.headlineSmall),
                ],
              ),
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
    print('connect');
  }
  void _reconnect() {
    print('reconnect');
  }

  void _newPassword() {
    print('new password');
  }
}
