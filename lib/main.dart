import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/listenForFire.dart';
import "components/recordSoundSample.dart";
import "components/lineplot.dart";
import 'screens/settings.dart';
import 'utils/SoundRecorder.dart';
import 'utils/smsRequest.dart';

const ignoreLowestFreqs = 200;

final simpleMovingAverageSmall = MovingAverage<double>(
  averageType: AverageType.simple,
  windowSize: 5,
  partialStart: true,
  getValue: (double n) => n,
  add: (List<double> data, num value) => 1.0 * value,
);

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final recorder = MyRecorder(chunkSize: 2048);
  final smsRequest = SmsRequest();

  List<double> sample = List.empty();
  List<double> scan = List.empty();

  bool closing = false;
  List<double> rawComparisons = <double>[];
  List<double> comparisons = <double>[];
  bool active = false;

  String phone = "";
  double threshold = 10000;

  final GlobalKey<ScaffoldState> _key = GlobalKey(); // Create a key

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) async {
      final p = prefs.getString("phone") ?? "";
      final t = prefs.getDouble("threshold") ?? 10000;
      setState(() {
        phone = p;
        threshold = t;
      });
    });
  }

  Future<void> setValues(String p, double th) async {
    setState(() {
      this.phone = p;
      this.threshold = th;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble("threshold", th);
    prefs.setString("phone", p);
  }

  @override
  Widget build(Object context) {
    return MaterialApp(
      home: Scaffold(
        key: _key,
        drawer: Builder(
          builder: (context) => // Ensure Scaffold is in context
              SettingsScreen(
            onClose: (String phone, String threshold) {
              print("GOT $phone $threshold");
              Scaffold.of(context).closeDrawer();
              final double thr = double.parse(threshold);
              setValues(phone, thr);
            },
            onChange: (String phone, String threshold) {
              print("GOT $phone $threshold");
              final double thr = double.parse(threshold);
              setValues(phone, thr);
            },
            initialPhone: phone,
            initialThreshold: "${threshold.toInt()}",
          ),
        ),
        appBar: AppBar(
          leading: Container(),
          actions: [
            Builder(
              builder: (context) => // Ensure Scaffold is in context
                  IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              RecordSoundSample(
                recorder: recorder,
                newMeanCallback: onNewSample,
              ),
              Container(
                height: 150,
                child: MyLinePlot(data: sample),
              ),
              ListenForFire(
                recorder: recorder,
                newScan: newScan,
                onStart: onStart,
              ),
              MyLinePlot(data: comparisons),
              Container(
                color: active
                    ? const Color.fromRGBO(0, 255, 0, 0.2)
                    : const Color.fromRGBO(0, 0, 0, 0),
                child: Text("$active"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onStart() {
    setState(() {
      closing = false;
      comparisons = List.empty();
      rawComparisons = List.empty();
    });
  }

  void onNewSample(List<double>? sample) {
    setState(() {
      this.sample = sample ?? List.empty();
    });
  }

  Future<void> newScan(List<double>? scan) async {
    double v = 0;
    if (scan != null) {
      // interesing freq range
      const from = 300;
      const to = 500;

      // remove median
      final median = (List.of(scan)..sort())[(scan.length * 0.50).toInt()];
      for (int i = 0; i < scan.length; ++i) {
        scan[i] = max(0, scan[i] - median);
      }

      // estimate energy
      double e = 0;
      for (int i = from; i < to; ++i) e += scan[i] * scan[i];
      e = sqrt(e / (to - from));

      // remove low freqs
      for (int i = 0; i < ignoreLowestFreqs; ++i) {
        scan[i] = 0;
      }

      // normalize
      final std = sqrt(
          scan.reduce((value, element) => value + element * element) /
              scan.length);
      for (int i = 0; i < scan.length; ++i) {
        scan[i] /= std;
      }

      // estimate cos similar
      v = 0;
      for (int i = from; i < to; ++i) {
        v += scan[i] * sample[i];
      }
      v /= (scan.length - ignoreLowestFreqs);
      v *= e;
    }

    final nextRawComparisons = rawComparisons.sublist(
        max(0, rawComparisons.length - ignoreLowestFreqs),
        rawComparisons.length)
      ..add(v);

    final smoothSmall = simpleMovingAverageSmall(nextRawComparisons);

    final fireSignalDetected =
        comparisons.length > 20 && (comparisons.lastOrNull ?? 0) > threshold;

    setState(() {
      this.scan = scan ?? List.empty();
      rawComparisons = nextRawComparisons;
      comparisons = smoothSmall;
      active = fireSignalDetected;
    });

    if (fireSignalDetected) {
      await recorder.stop();
      try {
        if (!closing && phone.length > 3) {
          closing = true;
          final response = await smsRequest.send(phone);
          print("DID IT $response");
        } else {
          print("SKIP SMS $closing $phone");
        }
      } catch (err) {
        print("Error $err");
      }
    }
  }
}
