import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationView extends StatefulWidget {
  const AuthenticationView({Key? key}) : super(key: key);

  @override
  AuthenticationState createState() => AuthenticationState();
}

class AuthenticationState extends State<AuthenticationView> {
  TextEditingController profileTokenController = TextEditingController();
  TextEditingController refreshTokenController = TextEditingController();
  String profileToken = '';
  String refreshToken = '';

  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  //Loading counter value on start
  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profileToken = (prefs.getString('profileToken') ?? '');
      profileTokenController.text = profileToken;
      refreshToken = (prefs.getString('refreshToken') ?? '');
      refreshTokenController.text = refreshToken;
    });
  }

  //Incrementing counter after click
  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('profileToken', profileToken);
      prefs.setString('refreshToken', refreshToken);
    });
  }

  onTapSave(BuildContext context) {
    if (profileToken.isEmpty) {
      showAlertDialog(
          context, 'MISSING INFO', "You need to input an PROFILE TOKEN");
    } else if (refreshToken.isEmpty) {
      showAlertDialog(
          context, 'MISSING INFO', "You need to input a REFRESH TOKEN");
    } else {
      setPrefs();
      SahhaFlutter.authenticate(profileToken, refreshToken)
          .then((success) =>
              {showAlertDialog(context, 'AUTHORIZED', success.toString())})
          .catchError((error, stackTrace) => {debugPrint(error.toString())});
    }
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
        title: const Text('Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: <Widget>[
              const Spacer(),
              const Icon(
                Icons.lock,
                size: 64,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: profileTokenController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "PROFILE TOKEN"),
                onChanged: (text) {
                  setState(() {
                    profileToken = profileTokenController.text;
                  });
                },
              ),
              TextField(
                controller: refreshTokenController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "REFRESH TOKEN"),
                onChanged: (text) {
                  setState(() {
                    refreshToken = refreshTokenController.text;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  onTapSave(context);
                },
                child: const Text('SAVE'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  setState(() {
                    profileTokenController.text = '';
                    refreshTokenController.text = '';
                  });
                },
                child: const Text('DELETE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
