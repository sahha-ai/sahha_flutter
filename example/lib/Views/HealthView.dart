import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class HealthView extends StatefulWidget {
  const HealthView({Key? key}) : super(key: key);

  @override
  State<HealthView> createState() => HealthState();
}

class HealthState extends State<HealthView> {
  SahhaActivityStatus activityStatus = SahhaActivityStatus.pending;

  @override
  void initState() {
    super.initState();
    debugPrint('init health');
    SahhaFlutter.activityStatus(SahhaActivity.health).then((value) {
      setState(() {
        activityStatus = value;
      });
      if (value == SahhaActivityStatus.enabled) {
        SahhaFlutter.postSensorData(sensors: [SahhaSensor.sleep]);
      }
      debugPrint('init health ' + describeEnum(activityStatus));
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
  }

  onTapEnable(BuildContext context) {
    SahhaFlutter.activate(SahhaActivity.health).then((value) {
      setState(() {
        activityStatus = value;
      });
      debugPrint('activate health ' + describeEnum(activityStatus));
    }).catchError((error, stackTrace) => {debugPrint(error.toString())});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(children: <Widget>[
            const Spacer(),
            const Icon(
              Icons.favorite,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text('Activity Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(describeEnum(activityStatus),
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: activityStatus == SahhaActivityStatus.enabled
                  ? null
                  : () {
                      onTapEnable(context);
                    },
              child: const Text('ENABLE'),
            ),
          ]),
        ),
      ),
    );
  }
}
