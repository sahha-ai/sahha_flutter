import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selectpicker/models/select_picker_item.dart';
import 'package:selectpicker/selectpicker.dart';
import 'package:selectpicker/styles/input_style.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<ProfileView> {
  // Replace age with birthDate
  String birthDate = ''; // "YYYY-MM-DD"
  DateTime? birthDateValue;

  String gender = '';

  @override
  void initState() {
    super.initState();

    SahhaFlutter.getDemographic()
        .then((value) => debugPrint(value))
        .catchError((error, stackTrace) => debugPrint(error.toString()));

    getPrefs();
  }

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final storedBirthDate = prefs.getString('birthDate') ?? '';
    DateTime? parsed;
    if (storedBirthDate.isNotEmpty) {
      try {
        parsed = DateTime.parse(storedBirthDate); // expects YYYY-MM-DD
      } catch (_) {
        parsed = null;
      }
    }

    setState(() {
      birthDate = storedBirthDate;
      birthDateValue = parsed;
      gender = (prefs.getString('gender') ?? '');
    });
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthDate', birthDate);
    await prefs.setString('gender', gender);
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = birthDateValue ?? DateTime(now.year - 25, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (selected == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(selected);
    setState(() {
      birthDateValue = selected;
      birthDate = formatted;
    });
  }

  void onTapSave(BuildContext context) {
    if (birthDate.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input a BIRTH DATE");
      return;
    }

    // Basic validation: ensure it's parseable and looks like YYYY-MM-DD
    DateTime? parsed;
    try {
      parsed = DateTime.parse(birthDate);
    } catch (_) {
      parsed = null;
    }
    if (parsed == null || birthDate.length != 10) {
      showAlertDialog(context, 'MISSING INFO', "BIRTH DATE must be YYYY-MM-DD");
      return;
    }

    if (gender.isEmpty) {
      showAlertDialog(context, 'MISSING INFO', "You need to input a GENDER");
      return;
    }

    setPrefs();

    final demographic = {
      'gender': gender,
      'birthDate': birthDate,
    };

    SahhaFlutter.postDemographic(demographic).then((success) {
      debugPrint(success.toString());
      showAlertDialog(context, "SAVE", success.toString());
    }).catchError((error, stackTrace) {
      debugPrint(error.toString());
      showAlertDialog(context, "SAVE", error.toString());
    });
  }

  void onTapFetch(BuildContext context) {
    SahhaFlutter.getDemographic().then((value) {
      debugPrint(value);
      showAlertDialog(context, "FETCH", value ?? "empty");
    }).catchError((error, stackTrace) {
      debugPrint(error.toString());
      showAlertDialog(context, "FETCH", error.toString());
    });
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    final alert = AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => alert,
    );
  }

  @override
  Widget build(BuildContext context) {
    final birthDateLabel = birthDate.isEmpty ? 'BIRTH DATE' : birthDate;

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
              const Icon(Icons.person, size: 64),
              const SizedBox(height: 20),

              // Birth date picker field
              InkWell(
                onTap: () => pickBirthDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'BIRTH DATE',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(birthDateLabel),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
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
                    // Use value.value if you want "male/female" instead of title
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => onTapSave(context),
                child: const Text('SAVE'),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => onTapFetch(context),
                child: const Text('FETCH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
