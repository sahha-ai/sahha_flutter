import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/Views/AnalyzationView.dart';
import 'package:sahha_flutter_example/Views/AuthenticationView.dart';
import 'package:sahha_flutter_example/Views/HomeView.dart';
import 'package:sahha_flutter_example/Views/ProfileView.dart';
import 'package:sahha_flutter_example/Views/SensorPermissionView.dart';

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
    SahhaFlutter.configure(
      environment: SahhaEnvironment.sandbox,
    )
        .then((success) => {debugPrint(success.toString())})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});

/*
    // Android only
    var notificationSettings = {
      'icon': 'Custom Icon',
      'title': 'Custom Title',
      'shortDescription': 'Custom Description'
    };

    // Use custom values
    SahhaFlutter.configure(
            environment: SahhaEnvironment.production,
            sensors: [SahhaSensor.device],
            notificationSettings: notificationSettings)
        .then((success) => {debugPrint(success.toString())})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});
        */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeView(),
        '/authentication': (BuildContext context) => const AuthenticationView(),
        '/profile': (BuildContext context) => const ProfileView(),
        '/permissions': (BuildContext context) => const SensorPermissionView(),
        '/analyzation': (BuildContext context) => const AnalyzationView(),
      },
    );
  }
}
