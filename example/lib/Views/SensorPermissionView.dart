import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class SensorPermissionView extends StatefulWidget {
  const SensorPermissionView({Key? key}) : super(key: key);

  @override
  State<SensorPermissionView> createState() => SensorPermissionState();
}

class SensorPermissionState extends State<SensorPermissionView> {
  SahhaSensorStatus sensorStatus = SahhaSensorStatus.pending;

  @override
  void initState() {
    super.initState();
    onTapGetSome(context);
  }

  onTapGetSome(BuildContext context) {
    SahhaFlutter.getSensorStatus(
            [SahhaSensor.sleep, SahhaSensor.step_count, SahhaSensor.heart_rate])
        .then((value) {
      setState(() {
        sensorStatus = value;
      });
      debugPrint('Get Some Sensors ' + sensorStatus.name);
    }).catchError((error) {
      debugPrint(error.toString());
    });
  }

  onTapGetEmpty(BuildContext context) {
    SahhaFlutter.getSensorStatus([]).then((value) {
      setState(() {
        sensorStatus = value;
      });
      debugPrint('Get Empty Sensors ' + sensorStatus.name);
    }).catchError((error) {
      debugPrint(error.toString());
    });
  }

  onTapEnableSome(BuildContext context) {
    SahhaFlutter.enableSensors(
            [SahhaSensor.sleep, SahhaSensor.step_count, SahhaSensor.heart_rate])
        .then((value) {
      setState(() {
        sensorStatus = value;
      });
      debugPrint('Enable Some Sensors ' + sensorStatus.name);
    }).catchError((error) {
      debugPrint(error.toString());
    });
  }

  onTapEnableEmpty(BuildContext context) {
    SahhaFlutter.enableSensors([]).then((value) {
      setState(() {
        sensorStatus = value;
      });
      debugPrint('Enable Empty Sensors ' + sensorStatus.name);
    }).catchError((error) {
      debugPrint(error.toString());
    });
  }

  openAppSettings(BuildContext context) {
    debugPrint('Open App Settings');
    SahhaFlutter.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Permissions'),
      ),
      body: ListView(padding: const EdgeInsets.all(40), children: <Widget>[
        const Spacer(),
        const Icon(
          Icons.sensors,
          size: 64,
        ),
        const SizedBox(height: 20),
        const Text('Sensor Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text(sensorStatus.name, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            onTapGetEmpty(context);
          },
          child: const Text('GET EMPTY'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            onTapGetSome(context);
          },
          child: const Text('GET SOME'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            onTapEnableEmpty(context);
          },
          child: const Text('ENABLE EMPTY'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            onTapEnableSome(context);
          },
          child: const Text('ENABLE SOME'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () {
            openAppSettings(context);
          },
          child: const Text('OPEN APP SETTINGS'),
        ),
      ]),
    );
  }
}
