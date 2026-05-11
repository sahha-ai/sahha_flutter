import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationView extends StatefulWidget {
  const AuthenticationView({Key? key}) : super(key: key);

  @override
  AuthenticationState createState() => AuthenticationState();
}

class AuthenticationState extends State<AuthenticationView> {
  TextEditingController appIdController = TextEditingController();
  TextEditingController appSecretController = TextEditingController();
  TextEditingController externalIdController = TextEditingController();
  String appId = 'dJ52F2MXsQ6xjJ6IPRahBG1S3ayzYUSo';
  String appSecret = 'bodDOI8MwQkIlZycZWAlzO7T6CamQ2fl6SpWt9U6vZc1itbqeECfslnecMRPyfDz';
  String externalId = '';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      appId = (prefs.getString('appId') ?? 'dJ52F2MXsQ6xjJ6IPRahBG1S3ayzYUSo');
      appIdController.text = appId;
      appSecret = (prefs.getString('appSecret') ?? 'bodDOI8MwQkIlZycZWAlzO7T6CamQ2fl6SpWt9U6vZc1itbqeECfslnecMRPyfDz');
      appSecretController.text = appSecret;
      externalId = (prefs.getString('externalId') ?? '');
      externalIdController.text = externalId;
    });

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final success = await SahhaFlutter.isAuthenticated();
      setState(() {
        _isAuthenticated = success;
      });
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('appId', appId);
      prefs.setString('appSecret', appSecret);
      prefs.setString('externalId', externalId);
    });
  }

  onTapSave(BuildContext context) async {
    if (appId.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input an APP ID");
    } else if (appSecret.isEmpty) {
      showAlertDialog(
          context, 'MISSING INFO', "You need to input an APP SECRET");
    } else if (externalId.isEmpty) {
      showAlertDialog(
          context, 'MISSING INFO', "You need to input an EXTERNAL ID");
    } else {
      try {
        final success = await SahhaFlutter.authenticate(
            appId: appId, appSecret: appSecret, externalId: externalId);
        showAlertDialog(context, 'AUTHENTICATED', success.toString());
        setPrefs();
        await _checkAuthentication();
      } catch (error) {
        debugPrint(error.toString());
        showAlertDialog(context, 'ERROR', error.toString());
      }
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAuthenticated ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAuthenticated ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAuthenticated ? 'Authenticated' : 'Not Authenticated',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.lock,
                size: 64,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: appIdController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "APP ID"),
                onChanged: (text) {
                  setState(() {
                    appId = appIdController.text;
                  });
                },
              ),
              TextField(
                controller: appSecretController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "APP SECRET"),
                onChanged: (text) {
                  setState(() {
                    appSecret = appSecretController.text;
                  });
                },
              ),
              TextField(
                controller: externalIdController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: "EXTERNAL ID"),
                onChanged: (text) {
                  setState(() {
                    externalId = externalIdController.text;
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
                child: const Text('AUTHENTICATE'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  try {
                    final success = await SahhaFlutter.deauthenticate();
                    showAlertDialog(
                        context, 'DEAUTHENTICATED', success.toString());
                    setState(() {
                      externalIdController.text = '';
                      externalId = '';
                    });
                    setPrefs();
                    await _checkAuthentication();
                  } catch (error) {
                    debugPrint(error.toString());
                    showAlertDialog(context, 'ERROR', error.toString());
                  }
                },
                child: const Text('DEAUTHENTICATE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
