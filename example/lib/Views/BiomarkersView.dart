import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiomarkersView extends StatefulWidget {
  const BiomarkersView({Key? key}) : super(key: key);

  @override
  BiomarkersState createState() => BiomarkersState();
}

class BiomarkersState extends State<BiomarkersView> {
  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  onTapGetBiomarkers(BuildContext context, bool isDaily) {
    if (isDaily) {
      SahhaFlutter.getBiomarkers(
              categories: SahhaBiomarkerCategory.values,
              types: SahhaBiomarkerType.values,
              startDate: DateTime.now(),
              endDate: DateTime.now())
          .then((value) {
        List<dynamic> data = jsonDecode(value);
        debugPrint(data.firstOrNull?.toString());
        showAlertDialog(context, value);
      }).catchError((error, stackTrace) => {debugPrint(error.toString())});
    } else {
      var week = DateTime.now().subtract(const Duration(days: 7));
      SahhaFlutter.getBiomarkers(
              categories: SahhaBiomarkerCategory.values,
              types: SahhaBiomarkerType.values,
              startDate: week,
              endDate: DateTime.now())
          .then((value) {
        List<dynamic> data = jsonDecode(value);
        debugPrint(data.firstOrNull?.toString());
        showAlertDialog(context, value);
      }).catchError((error, stackTrace) => {debugPrint(error.toString())});
    }
  }

  showAlertDialog(BuildContext context, String value) {
    AlertDialog alert = AlertDialog(
      title: const Text('BIOMARKERS'),
      content: SingleChildScrollView(
        child: Text(value),
      ),
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
          title: const Text('Biomarkers'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  const Icon(
                    Icons.insert_chart,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text('A new score will be available every 6 hours',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      onTapGetBiomarkers(context, false);
                    },
                    child: const Text('GET BIOMARKERS PREVIOUS WEEK'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      onTapGetBiomarkers(context, true);
                    },
                    child: const Text('GET BIOMARKERS TODAY'),
                  ),
                ]),
          ),
        ));
  }
}
