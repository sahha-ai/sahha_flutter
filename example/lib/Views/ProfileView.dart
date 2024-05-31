import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selectpicker/models/select_picker_item.dart';
import 'package:selectpicker/selectpicker.dart';
import 'package:selectpicker/styles/input_style.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<ProfileView> {
  TextEditingController ageController = TextEditingController();
  String ageString = '';
  int age = 0;
  String gender = '';

  @override
  void initState() {
    super.initState();

    SahhaFlutter.getDemographic()
        .then((value) => {debugPrint(value)})
        .catchError((error, stackTrace) => {debugPrint(error.toString())});

    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ageString = (prefs.getString('age') ?? '');
      ageController.text = ageString;
      gender = (prefs.getString('gender') ?? '');
    });
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('age', ageString);
      prefs.setString('gender', gender);
    });
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
      var demographic = {'age': int.tryParse(ageString), 'gender': gender};
      SahhaFlutter.postDemographic(demographic).then((success) {
        debugPrint(success.toString());
        showAlertDialog(context, "SAVE", success.toString());
      }).catchError((error, stackTrace) {
        debugPrint(error.toString());
        showAlertDialog(context, "SAVE", error.toString());
      });
    }
  }

  onTapFetch(BuildContext context) {
    SahhaFlutter.getDemographic().then((value) {
      debugPrint(value);
      showAlertDialog(context, "FETCH", value ?? "empty");
    }).catchError((error, stackTrace) {
      debugPrint(error.toString());
      showAlertDialog(context, "FETCH", error.toString());
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
              SelectPicker(
                hint: gender.isEmpty ? "GENDER" : gender,
                list: [
                  SelectPickerItem("Male", "male", null),
                  SelectPickerItem("Female", "female", null),
                  SelectPickerItem("Gender Diverse", "gender diverse", null),
                ],
                selectFirst: false,
                showId: false,
                onSelect: (value) {
                  setState(() {
                    gender = value.title.toString();
                  });
                },
                selectPickerInputStyle: SelectPickerInputStyle(),
                initialItem: gender,
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
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  onTapFetch(context);
                },
                child: const Text('FETCH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
