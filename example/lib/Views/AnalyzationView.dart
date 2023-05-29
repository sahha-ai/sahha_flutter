import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyzationView extends StatefulWidget {
  const AnalyzationView({Key? key}) : super(key: key);

  @override
  AnalyzationState createState() => AnalyzationState();
}

class AnalyzationState extends State<AnalyzationView> {
  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
    });
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
    });
  }

  onTapAnalyze(BuildContext context, bool isDaily) {
    if (isDaily) {
      SahhaFlutter.analyze()
          .then((value) => {showAlertDialog(context, value)})
          .catchError((error, stackTrace) => {debugPrint(error.toString())});
    } else {
      var week = DateTime.now().subtract(Duration(days: 7));
      SahhaFlutter.analyze(startDate: week, endDate: DateTime.now())
          .then((value) => {showAlertDialog(context, value)})
          .catchError((error, stackTrace) => {debugPrint(error.toString())});
    }
  }

  showAlertDialog(BuildContext context, String value) {
    AlertDialog alert = AlertDialog(
      title: const Text('ANALYSIS'),
      content: Text(value),
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
          title: const Text('Analyzation'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  const Icon(
                    Icons.query_stats,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text('A new analysis will be available every 24 hours',
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
                      onTapAnalyze(context, false);
                    },
                    child: const Text('ANALYZE PREVIOUS WEEK'),
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
                      onTapAnalyze(context, true);
                    },
                    child: const Text('ANALYZE PREVIOUS DAY'),
                  ),
                ]),
          ),
        ));
  }
}
