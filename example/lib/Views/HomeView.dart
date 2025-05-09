import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sahha Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: ListView(children: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(
                Icons.lock,
                size: 32,
              ),
              label: const Text('Authentication'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.all(20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/authentication');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.person,
                size: 32,
              ),
              label: const Text('Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.all(20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.sensors,
                size: 32,
              ),
              label: const Text('Sensor Permissions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/permissions');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.query_stats,
                size: 32,
              ),
              label: const Text('Scores'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/scores');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.insert_chart,
                size: 32,
              ),
              label: const Text('Biomarkers'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/biomarkers');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.pie_chart,
                size: 32,
              ),
              label: const Text('Stats'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.timer_outlined,
                size: 32,
              ),
              label: const Text('Samples'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/samples');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.psychology,
                size: 32,
              ),
              label: const Text('Insights'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/web');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.task_outlined,
                size: 32,
              ),
              label: const Text('Test Post Sensor Data'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                SahhaFlutter.postSensorData();
              },
            ),
          ]),
        ));
  }
}
