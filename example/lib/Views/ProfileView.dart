import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Extra demographic data
  // Controllers
  TextEditingController industryController = TextEditingController();
  TextEditingController occupationController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController birthCountryController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController ethnicityController = TextEditingController();
  TextEditingController incomeRangeController = TextEditingController();
  TextEditingController educationController = TextEditingController();
  TextEditingController relationshipController = TextEditingController();
  TextEditingController localeController = TextEditingController();
  TextEditingController livingArrangementController = TextEditingController();

  // Strings
  String industry = '';
  String occupation = '';
  String country = '';
  String birthCountry = '';
  String birthDate = '';
  String ethnicity = '';
  String incomeRange = '';
  String education = '';
  String relationship = '';
  String locale = '';
  String livingArrangement = '';

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
      genderController.text = gender;
      occupation = (prefs.getString('occupation') ?? '');
      occupationController.text = occupation;
      industry = (prefs.getString('industry') ?? '');
      industryController.text = industry;
      country = (prefs.getString('country') ?? '');
      countryController.text = country;
      birthCountry = (prefs.getString('birthCountry') ?? '');
      birthCountryController.text = birthCountry;
      birthDate = (prefs.getString('birthDate') ?? '');
      birthDateController.text = birthDate;
      ethnicity = (prefs.getString('ethnicity') ?? '');
      ethnicityController.text = ethnicity;
      incomeRange = (prefs.getString('incomeRange') ?? '');
      incomeRangeController.text = incomeRange;
      education = (prefs.getString('education') ?? '');
      educationController.text = education;
      relationship = (prefs.getString('relationship') ?? '');
      relationshipController.text = relationship;
      locale = (prefs.getString('locale') ?? '');
      localeController.text = locale;
      livingArrangement = (prefs.getString('livingArrangement') ?? '');
      livingArrangementController.text = livingArrangement;
    });
  }

  void setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('age', ageString);
      prefs.setString('gender', gender);
      prefs.setString('occupation', occupation);
      prefs.setString('industry', industry);
      prefs.setString('country', country);
      prefs.setString('birthCountry', birthCountry);
      prefs.setString('birthDate', birthDate);
      prefs.setString('ethnicity', ethnicity);
      prefs.setString('incomeRange', incomeRange);
      prefs.setString('education', education);
      prefs.setString('relationship', relationship);
      prefs.setString('locale', locale);
      prefs.setString('livingArrangement', livingArrangement);
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
      var demographic = {
        'age': int.tryParse(ageString),
        'gender': gender,
        'occupation': occupation.isEmpty ? null : occupation,
        'industry': industry.isEmpty ? null : industry,
        'country': country.isEmpty ? null : country,
        'birthCountry': birthCountry.isEmpty ? null : birthCountry,
        'birthDate': birthDate.isEmpty ? null : birthDate,
        'ethnicity': ethnicity.isEmpty ? null : ethnicity,
        'incomeRange': incomeRange.isEmpty ? null : incomeRange,
        'education': education.isEmpty ? null : education,
        'relationship': relationship.isEmpty ? null : relationship,
        'locale': locale.isEmpty ? null : locale,
        'livingArrangement':
            livingArrangement.isEmpty ? null : livingArrangement,
      };
      SahhaFlutter.postDemographic(demographic).then((success) {
        debugPrint(success.toString());
        showAlertDialog(context, "SAVE", success.toString());
      }).catchError((error, stackTrace) {
        debugPrint(error.toString());
        showAlertDialog(context, "SAVE", "error");
      });
    }
  }

  onTapFetch(BuildContext context) {
    SahhaFlutter.getDemographic().then((value) {
      debugPrint(value);
      showAlertDialog(context, "FETCH", value);
    }).catchError((error, stackTrace) {
      debugPrint(error.toString());
      showAlertDialog(context, "FETCH", "error");
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
          child: ListView(
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
              const SizedBox(height: 20),
              TextField(
                controller: occupationController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "OCCUPATION"),
                onSubmitted: (text) {
                  setState(() {
                    occupationController.text = text;
                    occupation = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: industryController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "INDUSTRY"),
                onSubmitted: (text) {
                  setState(() {
                    industryController.text = text;
                    industry = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: countryController,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 2,
                keyboardType: TextInputType.text,
                decoration:
                    const InputDecoration(labelText: "COUNTRY (CODE E.G. US)"),
                onSubmitted: (text) {
                  setState(() {
                    countryController.text = text.toUpperCase();
                    country = text.toUpperCase();
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: birthCountryController,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 2,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                    labelText: "COUNTRY OF BIRTH (CODE E.G. US)"),
                onSubmitted: (text) {
                  setState(() {
                    birthCountryController.text = text.toUpperCase();
                    birthCountry = text.toUpperCase();
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: birthDateController,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 10,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                    labelText: "DATE OF BIRTH (YYYY-MM-DD)"),
                onSubmitted: (text) {
                  setState(() {
                    birthDateController.text = text.toUpperCase();
                    birthDate = text.toUpperCase();
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ethnicityController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "ETHNICITY"),
                onSubmitted: (text) {
                  setState(() {
                    ethnicityController.text = text;
                    ethnicity = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: incomeRangeController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "INCOME RANGE"),
                onSubmitted: (text) {
                  setState(() {
                    incomeRangeController.text = text;
                    incomeRange = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: educationController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "EDUCATION"),
                onSubmitted: (text) {
                  setState(() {
                    educationController.text = text;
                    education = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: relationshipController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "RELATIONSHIP"),
                onSubmitted: (text) {
                  setState(() {
                    relationshipController.text = text;
                    relationship = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: localeController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "LOCALE"),
                onSubmitted: (text) {
                  setState(() {
                    localeController.text = text;
                    locale = text;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: livingArrangementController,
                autocorrect: true,
                enableSuggestions: true,
                keyboardType: TextInputType.text,
                decoration:
                    const InputDecoration(labelText: "LIVING ARRANGEMENT"),
                onSubmitted: (text) {
                  setState(() {
                    livingArrangementController.text = text;
                    livingArrangement = text;
                  });
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
