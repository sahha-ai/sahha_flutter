import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises `postDemographic` and `getDemographic`.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => ProfileState();
}

class ProfileState extends State<ProfileView> {
  /// Values posted to the API, paired with their display labels.
  static const List<DropdownMenuEntry<String>> genderEntries = [
    DropdownMenuEntry(value: 'male', label: 'Male'),
    DropdownMenuEntry(value: 'female', label: 'Female'),
    DropdownMenuEntry(value: 'gender diverse', label: 'Gender Diverse'),
  ];

  String birthDate = ''; // "YYYY-MM-DD"
  DateTime? birthDateValue;
  String gender = '';

  bool _isSaving = false;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();

    SahhaFlutter.getDemographic()
        .then((value) => debugPrint('Get Demographic Result: $value'))
        .catchError(
          (error, stackTrace) => debugPrint('Get Demographic Error: $error'),
        );

    getPrefs();
  }

  // 'birthDate' / 'gender' keys are kept as-is for backward compatibility.
  Future<void> getPrefs() async {
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

    // Older builds stored the display label ("Male"), so normalise before
    // handing the value to the dropdown.
    final storedGender = (prefs.getString('gender') ?? '').toLowerCase();
    final knownGender = genderEntries.any((e) => e.value == storedGender)
        ? storedGender
        : '';

    if (!mounted) return;
    setState(() {
      birthDate = storedBirthDate;
      birthDateValue = parsed;
      gender = knownGender;
    });
  }

  Future<void> setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthDate', birthDate);
    await prefs.setString('gender', gender);
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        birthDateValue ?? DateTime(now.year - 25, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (selected == null || !mounted) return;

    final formatted = DateFormat('yyyy-MM-dd').format(selected);
    setState(() {
      birthDateValue = selected;
      birthDate = formatted;
    });
  }

  Future<void> onTapSave() async {
    if (birthDate.isEmpty) {
      return _showMissingInfo('You need to input a BIRTH DATE');
    }

    // Basic validation: ensure it's parseable and looks like YYYY-MM-DD.
    DateTime? parsed;
    try {
      parsed = DateTime.parse(birthDate);
    } catch (_) {
      parsed = null;
    }
    if (parsed == null || birthDate.length != 10) {
      return _showMissingInfo('BIRTH DATE must be YYYY-MM-DD');
    }

    if (gender.isEmpty) {
      return _showMissingInfo('You need to input a GENDER');
    }

    setState(() => _isSaving = true);
    await setPrefs();

    final demographic = {'gender': gender, 'birthDate': birthDate};

    bool? success;
    Object? failure;
    try {
      success = await SahhaFlutter.postDemographic(demographic);
      debugPrint('Post Demographic Result: $success');
    } catch (error) {
      failure = error;
      debugPrint('Post Demographic Error: $error');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    await showResponseSheet(
      context,
      title: failure == null ? 'Saved' : 'Save failed',
      subtitle: 'SahhaFlutter.postDemographic',
      body: (failure ?? success).toString(),
      isError: failure != null,
    );
  }

  Future<void> onTapFetch() async {
    setState(() => _isFetching = true);

    String? value;
    Object? failure;
    try {
      value = await SahhaFlutter.getDemographic();
      debugPrint('Get Demographic Result: $value');
    } catch (error) {
      failure = error;
      debugPrint('Get Demographic Error: $error');
    }

    if (!mounted) return;
    setState(() => _isFetching = false);

    await showResponseSheet(
      context,
      title: failure == null ? 'Demographic' : 'Fetch failed',
      subtitle: 'SahhaFlutter.getDemographic',
      body: failure != null
          ? failure.toString()
          : tryPrettyJson(value ?? 'empty'),
      isError: failure != null,
    );
  }

  Future<void> _showMissingInfo(String message) {
    return showResponseSheet(
      context,
      title: 'Missing info',
      body: message,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _isSaving || _isFetching;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => pickBirthDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'BIRTH DATE',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        birthDate.isEmpty ? 'Not set' : birthDate,
                        style: birthDate.isEmpty
                            ? theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: gender.isEmpty ? null : gender,
                    label: const Text('GENDER'),
                    hintText: 'Not set',
                    enableSearch: false,
                    requestFocusOnTap: false,
                    expandedInsets: EdgeInsets.zero,
                    dropdownMenuEntries: genderEntries,
                    onSelected: (value) {
                      if (value == null) return;
                      setState(() => gender = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : onTapSave,
            child: _busyLabel(context, busy: _isSaving, label: 'SAVE'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy ? null : onTapFetch,
            child: _busyLabel(context, busy: _isFetching, label: 'FETCH'),
          ),
        ],
      ),
    );
  }

  static Widget _busyLabel(
    BuildContext context, {
    required bool busy,
    required String label,
  }) {
    if (!busy) return Text(label);
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
