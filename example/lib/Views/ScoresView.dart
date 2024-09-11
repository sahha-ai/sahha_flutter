import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoresView extends StatefulWidget {
  const ScoresView({Key? key}) : super(key: key);

  @override
  ScoresState createState() => ScoresState();
}

class ScoresState extends State<ScoresView> {
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

  onTapGetScores(BuildContext context, bool isDaily) {
    if (isDaily) {
      SahhaFlutter.getScores(types: [SahhaScoreType.activity, SahhaScoreType.sleep, SahhaScoreType.wellbeing])
          .then((value) => {showAlertDialog(context, value)})
          .catchError((error, stackTrace) => {debugPrint(error.toString())});
    } else {
      var week = DateTime.now().subtract(const Duration(days: 7));
      SahhaFlutter.getScoresDateRange(types: [SahhaScoreType.activity, SahhaScoreType.sleep, SahhaScoreType.wellbeing], startDate: week, endDate: DateTime.now())
          .then((value) => {showAlertDialog(context, value)})
          .catchError((error, stackTrace) => {debugPrint(error.toString())});
    }
  }

  showAlertDialog(BuildContext context, String value) {
    AlertDialog alert = AlertDialog(
      title: const Text('SCORES'),
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
          title: const Text('Scores'),
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
                      onTapGetScores(context, false);
                    },
                    child: const Text('GET SCORES PREVIOUS WEEK'),
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
                      onTapGetScores(context, true);
                    },
                    child: const Text('GET SCORES PREVIOUS DAY'),
                  ),
                ]),
          ),
        ));
  }
}
