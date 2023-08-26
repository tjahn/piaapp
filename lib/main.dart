/*import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:moving_average/moving_average.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
// */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';

import 'components/listenForFire.dart';
import "components/recordSoundSample.dart";
import "components/lineplot.dart";
import 'utils/SoundRecorder.dart';

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

  List<double> sample = List.empty();
  List<double> scan = List.empty();

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
              ),
              MyLinePlot(data: sample),
              MyLinePlot(data: scan),
              MyLinePlot(data: comparisons),
            ],
          ),
        ),
      ),
    );
  }

  void onNewSample(List<double>? sample) {
    setState(() {
      this.sample = sample ?? List.empty();
    });
  }

  final ignoreLowestFreqs = 50;

  void newScan(List<double>? scan) {
    double v = 0;
    if (scan != null) {
      double m0 = 0;
      for (int i = ignoreLowestFreqs; i < scan.length; ++i) {
        m0 += scan[i];
      }
      m0 /= (scan.length - ignoreLowestFreqs);

      double v2 = 0;
      for (int i = ignoreLowestFreqs; i < scan.length; ++i) {
        v2 += scan[i] * scan[i];
      }
      v2 = sqrt(v2 / (scan.length - ignoreLowestFreqs));

      for (int i = ignoreLowestFreqs; i < scan.length; ++i) {
        v += (scan[i] - m0) * sample[i];
      }
      v /= (scan.length - ignoreLowestFreqs);
    }

    final nextRawComparisons = rawComparisons.sublist(
        max(0, rawComparisons.length - ignoreLowestFreqs),
        rawComparisons.length)
      ..add(v);

    final smoothSmall = simpleMovingAverageSmall(nextRawComparisons);

    setState(() {
      this.scan = scan ?? List.empty();
      rawComparisons = nextRawComparisons;
      comparisons = smoothSmall;
      active = (comparisons.lastOrNull ?? 0) > 200;
    });
  }
}
