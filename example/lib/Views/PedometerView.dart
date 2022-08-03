import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class PedometerView extends StatefulWidget {
  const PedometerView({Key? key}) : super(key: key);

  @override
  State<PedometerView> createState() => PedometerState();
}

class PedometerState extends State<PedometerView> {
  SahhaSensorStatus sensorStatus = SahhaSensorStatus.pending;

  @override
  void initState() {
    super.initState();
    debugPrint('init pedometer');
    SahhaFlutter.getSensorStatus().then((value) {
      setState(() {
        sensorStatus = value;
      });
      debugPrint('init pedometer ' + describeEnum(sensorStatus));
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
  }

  onTapEnable(BuildContext context) {
    if (sensorStatus == SahhaSensorStatus.disabled) {
      openAppSettings(context);
    } else {
      SahhaFlutter.enableSensors().then((value) {
        setState(() {
          sensorStatus = value;
        });
        debugPrint('activate pedometer ' + describeEnum(sensorStatus));
      }).catchError((error, stackTrace) => {debugPrint(error.toString())});
    }
  }

  openAppSettings(BuildContext context) {
    debugPrint('openAppSettings');
    SahhaFlutter.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(children: <Widget>[
            const Spacer(),
            const Icon(
              Icons.directions_walk,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text('Sensor Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(describeEnum(sensorStatus),
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: sensorStatus == SahhaSensorStatus.enabled
                  ? null
                  : () {
                      onTapEnable(context);
                    },
              child: const Text('ENABLE'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                openAppSettings(context);
              },
              child: const Text('OPEN APP SETTINGS'),
            ),
          ]),
        ),
      ),
    );
  }
}
