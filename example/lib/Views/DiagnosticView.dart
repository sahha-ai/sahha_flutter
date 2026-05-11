import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class DiagnosticView extends StatefulWidget {
  const DiagnosticView({Key? key}) : super(key: key);

  @override
  DiagnosticState createState() => DiagnosticState();
}

class DiagnosticState extends State<DiagnosticView> {
  String _resultText = '';
  bool _isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Diagnostic'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  const Icon(
                    Icons.bug_report,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                      'Upload a diagnostic report to Sahha for debugging',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18)),
            
                  const SizedBox(height: 20),
                  if (_resultText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _resultText.startsWith('Error')
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _resultText.startsWith('Error')
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: SelectableText(
                        _resultText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _resultText.startsWith('Error')
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ),
                  const Spacer(),
                ]),
          ),
        ));
  }
}
