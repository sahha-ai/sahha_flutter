import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationView extends StatefulWidget {
  const AuthenticationView({Key? key}) : super(key: key);

  @override
  AuthenticationState createState() => AuthenticationState();
}

class AuthenticationState extends State<AuthenticationView> {
  TextEditingController customerController = TextEditingController();
  TextEditingController profileController = TextEditingController();
  String customerId = '';
  String profileId = '';

  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  //Loading counter value on start
  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      customerId = (prefs.getString('customerId') ?? '');
      customerController.text = customerId;
      profileId = (prefs.getString('profileId') ?? '');
      profileController.text = profileId;
    });
  }

  //Incrementing counter after click
  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('customerId', customerId);
      prefs.setString('profileId', profileId);
    });
  }

  onTapLogin(BuildContext context) {
    if (customerId.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input a CUSTOMER ID");
    } else if (profileId.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input a PROFILE ID");
    } else {
      setPrefs();
      SahhaFlutter.authenticate(customerId, profileId)
          .then((value) => {showAlertDialog(context, 'AUTHORIZED', value)})
          .catchError((error, stackTrace) => {
        debugPrint(error.toString())
      });
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
                controller: customerController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "CUSTOMER ID"),
                onChanged: (text) {
                  setState(() {
                    customerId = customerController.text;
                  });
                },
              ),
              TextField(
                controller: profileController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "PROFILE ID"),
                onChanged: (text) {
                  setState(() {
                    profileId = profileController.text;
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
                  onTapLogin(context);
                },
                child: const Text('LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
