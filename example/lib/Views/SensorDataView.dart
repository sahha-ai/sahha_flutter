import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

class SensorDataView extends StatefulWidget {
  const SensorDataView({Key? key}) : super(key: key);

  @override
  SensorDataState createState() => SensorDataState();
}

class SensorDataState extends State<SensorDataView> {
  TextEditingController sensorController = TextEditingController();
  TextEditingController sensorDataController = TextEditingController();
  var sensors = ["Sleep", "Pedometer", "Device"];
  String sensor = '';
  String sensorData = 'Awaiting data...';

  onTapPicker(BuildContext context) {
    Picker(
        adapter: PickerDataAdapter<String>(pickerdata: sensors),
        changeToFirst: false,
        hideHeader: false,
        title: const Text('SENSORS'),
        onConfirm: (Picker picker, List value) {
          var index = value[0];
          var string = sensors[index];
          sensorController.text = string;
          sensor = string;
          var sensorString = sensors.indexOf(sensor);
          debugPrint(sensorString.toString());
          var sahhaSensor = SahhaSensor.values.elementAt(sensorString);
          debugPrint(sahhaSensor.toString());

          SahhaFlutter.getSensorData(sahhaSensor).then((data) {
            setState(() {
              sensorDataController.text = data;
            });
          }).onError((error, stackTrace) {
            setState(() {
              sensorDataController.text = "No data found";
            });
          });
        }).showModal(this.context);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height - 259;

    return Scaffold(
        appBar: AppBar(title: const Text('Sensor Data')),
        body: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
                child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                GestureDetector(
                  child: TextField(
                    controller: sensorController,
                    enabled: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: "SENSOR"),
                  ),
                  onTap: () {
                    onTapPicker(context);
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: height,
                 child: SingleChildScrollView(
                   scrollDirection: Axis.vertical,
                   child: Text(sensorDataController.text),
                 ),
                ),
              ],
            ))));
  }
}
