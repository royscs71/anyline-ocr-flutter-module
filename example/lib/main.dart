import 'dart:convert';
import 'package:anyline_plugin_example/result.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:anyline_plugin/anyline_plugin.dart';

import 'result_display.dart';
import 'result_list.dart';
import 'scan_modes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        ResultList.routeName: (context) => ResultList(),
        ResultDisplay.routeName: (context) => ResultDisplay(),
        FullScreenImage.routeName: (context) => FullScreenImage(),
        CompositeResultDisplay.routeName: (context) => CompositeResultDisplay(),
      },
      home: AnylineDemo(),
      theme: ThemeData(
        brightness: Brightness.light,
        accentColor: Colors.black87,
      ),
    );
  }
}

class AnylineDemo extends StatefulWidget {
  @override
  _AnylineDemoState createState() => _AnylineDemoState();
}

class _AnylineDemoState extends State<AnylineDemo> {
  AnylinePlugin anylinePlugin;

  String _sdkVersion = 'Unknown';
  String _configJson;
  List<Result> _results = [];

  @override
  void initState() {
    super.initState();
    initSdkState();
  }

  Future<void> initSdkState() async {
    String sdkVersion;
    try {
      sdkVersion = await AnylinePlugin.sdkVersion;
      anylinePlugin = AnylinePlugin();
    } on PlatformException {
      sdkVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      _sdkVersion = sdkVersion;
    });
  }

  Future<void> startAnyline(ScanMode mode) async {
    try {
      await _loadJsonConfigFromFile(mode.key);
      String stringResult = await anylinePlugin.startScanning(_configJson);

      Map<String, dynamic> jsonResult = jsonDecode(stringResult);

      Result result = Result(jsonResult, mode, DateTime.now());

      Navigator.pushNamed(
          context,
          mode.isCompositeScan()
              ? CompositeResultDisplay.routeName
              : ResultDisplay.routeName,
          arguments: result);

      setState(() {
        _results.insert(0, result);
      });
    } catch (e) {
      // TODO: Exception Handling
    }
  }

  Future<void> _loadJsonConfigFromFile(String config) async {
    String configJson =
        await rootBundle.loadString("config/${config}Config.json");

    setState(() {
      _configJson = configJson;
    });
  }

  // LAYOUT PART

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anyline Plugin Demo'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
              icon: Icon(Icons.folder_special),
              onPressed: () {
                Navigator.pushNamed(context, ResultList.routeName,
                    arguments: _results);
              })
        ],
      ),
      body: Center(
        child: ListView(
          padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
          children: [
            _useCase(
              'METER READING',
              [
                _scanButton(ScanMode.AnalogMeter),
                _scanButton(ScanMode.DigitalMeter),
                _scanButton(ScanMode.SerialNumber),
                _scanButton(ScanMode.DialMeter),
                _scanButton(ScanMode.DotMatrix),
              ],
            ),
            _useCase(
              'ID',
              [
                _scanButton(ScanMode.DrivingLicense),
                _scanButton(ScanMode.MRZ),
                _scanButton(ScanMode.GermanIDFront),
                _scanButton(ScanMode.Barcode_PDF417),
                _scanButton(ScanMode.UniversalId),
              ],
            ),
            _useCase(
              'VEHICLE',
              [
                _scanButton(ScanMode.LicensePlate),
                _scanButton(ScanMode.TIN),
              ],
            ),
            _useCase(
              'OCR',
              [
                _scanButton(ScanMode.Iban),
                _scanButton(ScanMode.Voucher),
              ],
            ),
            _useCase(
              'MRO',
              [
                _scanButton(ScanMode.VIN),
                _scanButton(ScanMode.USNR),
                _scanButton(ScanMode.ContainerShip),
              ],
            ),
            _useCase(
              'OTHER',
              [
                _scanButton(ScanMode.Barcode),
                _scanButton(ScanMode.Document),
                _scanButton(ScanMode.CattleTag),
                _scanButton(ScanMode.SerialScanning),
                _scanButton(ScanMode.ParallelScanning),
              ],
            ),
            Divider(),
            Text('Running on Anyline SDK Version $_sdkVersion\n'),
          ],
        ),
      ),
    );
  }

  Widget _useCase(String label, List<Widget> children) {
    return Card(
        color: Colors.white,
        margin: EdgeInsets.only(top: 15),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _heading6(label),
              SizedBox(height: 10),
              Column(children: children)
            ],
          ),
        ));
  }

  Widget _heading6(String text) {
    return Text(text, style: Theme.of(context).textTheme.headline6);
  }

  Widget _scanButton(ScanMode mode) {
    return Container(
      width: double.infinity,
      child: MaterialButton(
        onPressed: () {
          startAnyline(mode);
        },
        child: Text(mode.label),
        color: Colors.black87,
        textColor: Colors.white,
      ),
    );
  }
}
