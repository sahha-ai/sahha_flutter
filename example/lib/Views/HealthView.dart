import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sahha_flutter/sahha_flutter.dart';

class HealthView extends StatefulWidget {
  const HealthView({Key? key}) : super(key: key);

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  String _bundleId = 'Unknown app';
  String _platformVersion = 'Unknown';
  String _batteryLevel = 'Unknown battery level.';
  ActivityStatus _activityStatus = ActivityStatus.pending;

  @override
  void initState() {
    super.initState();
    initSahhaState();
  }

  // Sahha messages are asynchronous, so we initialize in an async method.
  Future<void> initSahhaState() async {
    String platformVersion = await SahhaFlutter.platformVersion;

    String batteryLevel = await SahhaFlutter.batteryLevel;

    String bundleId = await SahhaFlutter.bundleId;

    String token = await SahhaFlutter.authenticate("CUSTOMER_ID", "PROFILE_ID");

    ActivityStatus activityStatus = await SahhaFlutter.activityStatus;
    print(activityStatus);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _batteryLevel = batteryLevel;
      _bundleId = bundleId;
      _activityStatus = activityStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
      ),
      body: Center(
        child: Column(children: <Widget>[
          const Text("Hello\n"),
          Text('$_bundleId\n'),
          Text('Running on: $_platformVersion\n'),
          Text('$_batteryLevel\n'),
          Text('Activity Status: $_activityStatus\n'),
          ElevatedButton(
            // Within the `FirstScreen` widget
            onPressed: () {
              // Navigate to the second screen using a named route.
              Navigator.pushNamed(context, '/authentication');
            },
            child: const Text('Authentication'),
          ),
        ]),
      ),
    );
  }
}
