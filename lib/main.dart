import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';

import 'components/listenForFire.dart';
import "components/recordSoundSample.dart";
import "components/lineplot.dart";
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

  @override
  Widget build(Object context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              RecordSoundSample(
                recorder: recorder,
                newMeanCallback: onNewSample,
              ),
              ListenForFire(
                recorder: recorder,
                newScan: newScan,
                onStart: onStart,
              ),
              MyLinePlot(data: sample),
              MyLinePlot(data: scan),
              MyLinePlot(data: comparisons),
              Text("$active"),
            ],
          ),
        ),
      ),
    );
  }

  void onStart() {
    closing = true;
  }

  void onNewSample(List<double>? sample) {
    setState(() {
      this.sample = sample ?? List.empty();
    });
  }

  Future<void> newScan(List<double>? scan) async {
    double v = 0;
    if (scan != null) {
      final median = (List.of(scan)..sort())[(scan.length * 0.30).toInt()];

      double v2 = 0;
      for (int i = ignoreLowestFreqs; i < scan.length; ++i) {
        v2 += scan[i] * scan[i];
      }
      v2 = sqrt(v2 / (scan.length - ignoreLowestFreqs));

      for (int i = ignoreLowestFreqs; i < scan.length; ++i) {
        v += (scan[i] - median) * sample[i];
      }
      v /= (scan.length - ignoreLowestFreqs);
    }

    final nextRawComparisons = rawComparisons.sublist(
        max(0, rawComparisons.length - ignoreLowestFreqs),
        rawComparisons.length)
      ..add(v);

    final smoothSmall = simpleMovingAverageSmall(nextRawComparisons);

    final fireSignalDetected = (comparisons.lastOrNull ?? 0) > 500e3;

    setState(() {
      this.scan = scan ?? List.empty();
      rawComparisons = nextRawComparisons;
      comparisons = smoothSmall;
      active = fireSignalDetected;
    });

    if (fireSignalDetected) {
      await recorder.stop();
      try {
        if (!closing) {
          closing = true;
          final response = await smsRequest.send("0041762266149");
          print("DID IT $response");
        }
      } catch (err) {
        print(err);
      }
    }
  }
}
