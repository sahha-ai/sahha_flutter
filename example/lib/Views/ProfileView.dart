import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_picker/flutter_picker.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<ProfileView> {
  TextEditingController ageController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  String ageString = '';
  int age = 0;
  String gender = '';
  var genders = ["Male", "Female", "Gender Diverse"];

  @override
  void initState() {
    super.initState();

    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ageString = (prefs.getString('age') ?? '');
      ageController.text = ageString;
      gender = (prefs.getString('gender') ?? '');
      genderController.text = gender;
    });
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('age', ageString);
      prefs.setString('gender', gender);
    });
  }

  onTapPicker(BuildContext context) {
    Picker(
        adapter: PickerDataAdapter<String>(pickerdata: genders),
        changeToFirst: true,
        hideHeader: false,
        title: const Text('GENDER'),
        onConfirm: (Picker picker, List value) {
          var index = value[0];
          var string = genders[index];
          setState(() {
            genderController.text = string;
            gender = string;
          });
        }).showModal(this.context);
  }

  onTapSave(BuildContext context) {
    if (ageString.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input an AGE");
    } else if (int.tryParse(ageString) == null) {
      showAlertDialog(context, 'MISSING INFO', "AGE must be a number");
    } else if (gender.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input a GENDER");
    } else {
      setPrefs();
      SahhaFlutter.postDemographic(age: int.tryParse(ageString), gender: gender)
          .then((success) => {debugPrint(success.toString())})
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
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: <Widget>[
              const Spacer(),
              const Icon(
                Icons.person,
                size: 64,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ageController,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 3,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: "AGE"),
                onSubmitted: (text) {
                  String textString = int.tryParse(text)?.toString() ?? '';
                  setState(() {
                    ageController.text = textString;
                    ageString = textString;
                  });
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                child: TextField(
                  controller: genderController,
                  enabled: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: "GENDER"),
                ),
                onTap: () {
                  onTapPicker(context);
                },
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
                  onTapSave(context);
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
