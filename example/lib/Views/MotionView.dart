import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class MotionView extends StatefulWidget {
  const MotionView({Key? key}) : super(key: key);

  @override
  State<MotionView> createState() => MotionState();
}

class MotionState extends State<MotionView> {
  SahhaActivityStatus activityStatus = SahhaActivityStatus.pending;

  @override
  void initState() {
    super.initState();
    debugPrint('init motion');
    SahhaFlutter.activityStatus(SahhaActivity.motion).then((value) {
      setState(() {
        activityStatus = value;
      });
      debugPrint('init motion ' + describeEnum(activityStatus));
    }).catchError((error) {
      debugPrint(error);
    });
  }

  onTapEnable(BuildContext context) {
    if (activityStatus == SahhaActivityStatus.disabled) {
      SahhaFlutter.promptUserToActivate(SahhaActivity.motion).then((value) {
        setState(() {
          activityStatus = value;
        });
        debugPrint('activate motion ' + describeEnum(activityStatus));
      }).catchError((error) {
        debugPrint(error);
      });
    } else {
      SahhaFlutter.activate(SahhaActivity.motion).then((value) {
        setState(() {
          activityStatus = value;
        });
        debugPrint('activate motion ' + describeEnum(activityStatus));
      }).catchError((error) {
        debugPrint(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion'),
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
