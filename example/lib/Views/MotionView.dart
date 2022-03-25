import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sahha_flutter/sahha_flutter.dart';

class MotionView extends StatelessWidget {
  const MotionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion'),
      ),
      body: Center(
        child: Column(children: <Widget>[
          const Text("hello"),
          const Text("friends"),
        ]),
      ),
    );
  }
}
