import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:selectpicker/models/select_picker_item.dart';
import 'package:selectpicker/selectpicker.dart';
import 'package:selectpicker/styles/input_style.dart';

class StatsView extends StatefulWidget {
  const StatsView({Key? key}) : super(key: key);

  @override
  StatsState createState() => StatsState();
}

class StatsState extends State<StatsView> {
  String sensor = '';

  @override
  void initState() {
    super.initState();
  }

  onTapGetStats(BuildContext context) {
    SahhaFlutter.getStatsDateRange(
        sensor:
            SahhaSensor.values.firstWhere((element) => element.name == sensor),
        startDate: DateTime.timestamp().subtract(const Duration(days: 7)),
        endDate: DateTime.timestamp())
    .then((value) {
      List<dynamic> data = jsonDecode(value);
      debugPrint(data.firstOrNull?.toString());
      showAlertDialog(context, "STATS", value);
    });
  }

  showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: <Widget>[
              const Spacer(),
              const Icon(
                Icons.pie_chart,
                size: 64,
              ),
              const SizedBox(height: 20),
              SelectPicker(
                hint: sensor.isEmpty ? "SENSOR" : sensor,
                list: [
                  for (var sensor in SahhaSensor.values)
                    SelectPickerItem(sensor.name, sensor.name, null)
                ],
                selectFirst: false,
                showId: false,
                onSelect: (value) {
                  setState(() {
                    sensor = value.title.toString();
                    debugPrint(sensor);
                  });
                },
                selectPickerInputStyle: SelectPickerInputStyle(),
                initialItem: sensor,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  onTapGetStats(context);
                },
                child: const Text('GET STATS'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
