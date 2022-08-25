import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/Views/AnalyzationView.dart';
import 'package:sahha_flutter_example/Views/AuthenticationView.dart';
import 'package:sahha_flutter_example/Views/HomeView.dart';
import 'package:sahha_flutter_example/Views/PedometerView.dart';
import 'package:sahha_flutter_example/Views/ProfileView.dart';
import 'package:sahha_flutter_example/Views/SensorDataView.dart';
import 'package:sahha_flutter_example/Views/SleepView.dart';

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

    // Use default values
    SahhaFlutter.configure(environment: SahhaEnvironment.development)
        .then((success) => {debugPrint(success.toString())})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});

/*
    // Use custom values
    SahhaFlutter.configure(
            environment: SahhaEnvironment.production,
            sensors: [SahhaSensor.device],
            postSensorDataManually: true)
        .then((success) => {debugPrint(success.toString())})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});
        */
  }

  @override
  Widget build(BuildContext context) {
    const sahhaDark = MaterialColor(0xff333242, <int, Color>{
      50: Color(0xff333242),
      100: Color(0xff333242),
      200: Color(0xff333242),
      300: Color(0xff333242),
      400: Color(0xff333242),
      500: Color(0xff333242),
      600: Color(0xff333242),
      700: Color(0xff333242),
      800: Color(0xff333242),
      900: Color(0xff333242),
    });

    return MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const HomeView(),
          '/authentication': (BuildContext context) =>
              const AuthenticationView(),
          '/profile': (BuildContext context) => const ProfileView(),
          '/sleep': (BuildContext context) => const SleepView(),
          '/pedometer': (BuildContext context) => const PedometerView(),
          '/analyzation': (BuildContext context) => const AnalyzationView(),
          '/sensor_data': (BuildContext context) => const SensorDataView()
        },
        theme: ThemeData(
          fontFamily: 'Rubik',
          primarySwatch: sahhaDark,
        ));
  }
}
