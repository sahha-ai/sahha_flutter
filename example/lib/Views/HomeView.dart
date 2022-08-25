import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 70,
                width: 70,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    "assets/logo.png",
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const Text('Sahha Demo'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: <
                    Widget>[
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
                  Icons.dark_mode,
                  size: 32,
                ),
                label: const Text('Sleep'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/sleep');
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.directions_walk,
                  size: 32,
                ),
                label: const Text('Pedometer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/pedometer');
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.query_stats,
                  size: 32,
                ),
                label: const Text('Analyzation'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/analyzation');
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.bar_chart,
                  size: 32,
                ),
                label: const Text('View Sensor Data'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/sensor_data');
                },
              ),
            ]),
          ),
        ));
  }
}
