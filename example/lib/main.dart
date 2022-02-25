import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _bundleId = 'Unknown app';
  String _platformVersion = 'Unknown';
  String _batteryLevel = 'Unknown battery level.';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await SahhaFlutter.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    String batteryLevel = await SahhaFlutter.batteryLevel;

    String bundleId = await SahhaFlutter.bundleId;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _batteryLevel = batteryLevel;
      _bundleId = bundleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sahha Example'),
        ),
        body: Center(
          child: Column(children: <Widget>[
            const Text("Hello\n"),
            Text('$_bundleId\n'),
            Text('Running on: $_platformVersion\n'),
            Text('$_batteryLevel\n'),
          ]),
        ),
      ),
    );
  }
}
