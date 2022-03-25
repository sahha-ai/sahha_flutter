import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
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
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                  if (Platform.isIOS)
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.favorite,
                        size: 32,
                      ),
                      label: const Text('Health'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/health');
                      },
                    ),
                  if (Platform.isIOS) const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.directions_walk,
                      size: 32,
                    ),
                    label: const Text('Motion'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/motion');
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/analyzation');
                    },
                  ),
                ]),
          ),
        ));
  }
}
