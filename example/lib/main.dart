import 'package:flutter/material.dart';

import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/Views/HomeView.dart';
import 'package:sahha_flutter_example/Views/AuthenticationView.dart';
import 'package:sahha_flutter_example/Views/HealthView.dart';
import 'package:sahha_flutter_example/Views/MotionView.dart';
import 'package:sahha_flutter_example/Views/AnalyzationView.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    SahhaFlutter.configure(environment: SahhaEnvironment.development);

    /*
    SahhaFlutter.configure(
        environment: SahhaEnvironment.production,
        sensors: [SahhaSensor.device],
        postActivityManually: true);
        */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeView(),
        '/authentication': (BuildContext context) => const AuthenticationView(),
        '/health': (BuildContext context) => const HealthView(),
        '/motion': (BuildContext context) => const MotionView(),
        '/analyzation': (BuildContext context) => const AnalyzationView(),
      },
    );
  }
}
