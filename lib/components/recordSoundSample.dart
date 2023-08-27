import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';
import 'package:piaapp/main.dart';

import '../utils/SoundRecorder.dart';

class RecordSoundSample extends StatefulWidget {
  final MyRecorder recorder;
  final Function(List<double>?) newMeanCallback;

  final simpleMovingAverage = MovingAverage<double>(
    averageType: AverageType.simple,
    windowSize: 3,
    partialStart: true,
    getValue: (double n) => n,
    add: (List<double> data, num value) => 1.0 * value,
  );

  RecordSoundSample({
    super.key,
    required this.recorder,
    required this.newMeanCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return RecordSoundSampleState();
  }
}

class RecordSoundSampleState extends State<RecordSoundSample> {
  bool recording = false;
  int numRecordings = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        recording
            ? ElevatedButton(
                onPressed: stopRecording,
                child: const Text("stop"),
              )
            : ElevatedButton(
                onPressed: startRecording,
                child: const Text("Take sample"),
              ),
        Text("${numRecordings}"),
      ],
    );
  }

  void startRecording() async {
    setState(() {
      recording = true;
      numRecordings = 0;
    });

    if (widget.recorder.isRecording) {
      await widget.recorder.stop();
    }

    final stream = await widget.recorder.start();

    List<Float64List> recordings = [];
    final completer = Completer();
    stream.listen(
      (event) {
        final d = event.buffer.asInt16List();
        widget.recorder.stft.run(d.map((e) => 1.0 * e).toList(), (p0) {
          recordings.add(p0.discardConjugates().magnitudes());
        });
        setState(() {
          numRecordings = recordings.length;
        });
      },
      onDone: () {
        completer.complete();
      },
      onError: (error) {
        completer.completeError(error);
      },
      cancelOnError: false,
    );

    setState(() {
      recording = true;
    });
    await completer.future;
    setState(() {
      recording = false;
    });

    if (recordings.isNotEmpty) {
      if (true) {
        final means = <Float64List, double>{};
        for (final r in recordings) {
          means[r] = r.reduce((value, element) => (value + element)) / r.length;
        }
        recordings.sort((a, b) => (means[a]!.compareTo(means[b]!)));
        recordings = recordings.sublist(0, max(1, recordings.length ~/ 2));
      }
      var res = recordings.first;
      for (int j = 1; j < recordings.length; j++) {
        for (int i = 0; i < res.length; ++i) {
          res[i] += recordings[j][i];
        }
      }
      for (int i = 0; i < res.length; ++i) {
        res[i] /= recordings.length;
      }

      final median = (List.of(res)..sort())[(res.length * 0.85).toInt()];
      for (int i = 0; i < res.length; ++i) {
        res[i] = max(0, res[i] - median);
      }

      for (int i = 0; i < ignoreLowestFreqs; ++i) {
        res[i] = 0;
      }

      final v = sqrt(res.reduce((value, element) => value + element * element) /
          res.length);
      for (int i = 0; i < res.length; ++i) res[i] /= v;

      widget.newMeanCallback(widget.simpleMovingAverage(res));
    }
  }

  void stopRecording() async {
    await widget.recorder.stop();
  }
}
