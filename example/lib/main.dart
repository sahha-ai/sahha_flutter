import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/Views/AuthenticationView.dart';
import 'package:sahha_flutter_example/Views/BiomarkersView.dart';
import 'package:sahha_flutter_example/Views/HomeView.dart';
import 'package:sahha_flutter_example/Views/ProfileView.dart';
import 'package:sahha_flutter_example/Views/SamplesView.dart';
import 'package:sahha_flutter_example/Views/ScoresView.dart';
import 'package:sahha_flutter_example/Views/SensorDiagnosticsView.dart';
import 'package:sahha_flutter_example/Views/SensorPermissionView.dart';
import 'package:sahha_flutter_example/Views/StatsView.dart';
import 'package:sahha_flutter_example/Views/StressLabView.dart';
import 'package:sahha_flutter_example/Views/WebView.dart';
import 'package:sahha_flutter_example/services/stress_lab.dart';
import 'package:sahha_flutter_example/theme.dart';

Future<void> main() async {
  // The Stress Lab's startup flags decide how the SDK is configured, so they
  // have to be read before the first configure() call.
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await StressLabSettings.load();
  runApp(App(settings: settings));
}

class App extends StatefulWidget {
  const App({super.key, required this.settings});

  final StressLabSettings settings;

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    // Dispatched first so its channel call is in flight before the race below.
    unawaited(_configure());

    if (widget.settings.coldLaunchRace) {
      unawaited(_coldLaunchRace());
    }
  }

  Future<void> _configure() async {
    try {
      final success = await configureSahha(
        environment: widget.settings.environment,
        enableMotionTrigger: widget.settings.enableMotionTrigger,
      );
      debugPrint('Configure Success Result: $success');
    } catch (error) {
      debugPrint('Configure Error: $error');
    }
  }

  /// D1 on a cold launch: an auth-gated call fired immediately after
  /// `configure()` without awaiting it. Anything other than scores or a real
  /// API error — in particular the SDK's unauthorized message while a profile
  /// is signed in — is the regression this exists to catch.
  Future<void> _coldLaunchRace() async {
    final now = DateTime.now();
    try {
      final value = await SahhaFlutter.getScores(
        types: [SahhaScoreType.wellbeing],
        startDateTime: now.subtract(const Duration(days: 7)),
        endDateTime: now,
      );
      debugPrint('Cold-launch race getScores Result: $value');
      await ColdLaunchRaceOutcome.record(
        'getScores returned ${value.length} chars',
      );
    } catch (error) {
      debugPrint('Cold-launch race getScores Error: $error');
      await ColdLaunchRaceOutcome.record('getScores FAILED: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahha Demo',
      theme: SahhaAppTheme.light(),
      darkTheme: SahhaAppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeView(),
        '/authentication': (BuildContext context) => const AuthenticationView(),
        '/profile': (BuildContext context) => const ProfileView(),
        '/permissions': (BuildContext context) => const SensorPermissionView(),
        '/diagnostics': (BuildContext context) => const SensorDiagnosticsView(),
        '/stress': (BuildContext context) => const StressLabView(),
        '/scores': (BuildContext context) => const ScoresView(),
        '/biomarkers': (BuildContext context) => const BiomarkersView(),
        '/stats': (BuildContext context) => const StatsView(),
        '/samples': (BuildContext context) => const SamplesView(),
        '/web': (BuildContext context) => const WebView(),
      },
    );
  }
}
