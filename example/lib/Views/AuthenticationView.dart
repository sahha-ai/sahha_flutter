import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

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
  }

  onTapLogin(BuildContext context) {
    if (customerId.isEmpty) {
      showAlertDialog(context, "CUSTOMER ID");
    } else if (profileId.isEmpty) {
      showAlertDialog(context, "PROFILE ID");
    } else {
      SahhaFlutter.authenticate(customerId, profileId)
          .then((value) => {showAlertDialog(context, value)})
          .catchError((error) {
        debugPrint(error);
      });
    }
  }

  showAlertDialog(BuildContext context, String value) {
    AlertDialog alert = AlertDialog(
      title: const Text('MISSING INFO'),
      content: Text("You need to input a $value"),
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
