import 'dart:async';
import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';

import '../main.dart';
import '../utils/SoundRecorder.dart';

final simpleMovingAverage = MovingAverage<double>(
  averageType: AverageType.simple,
  windowSize: 5,
  partialStart: true,
  getValue: (double n) => n,
  add: (List<double> data, num value) => 1.0 * value,
);

class ListenForFire extends StatefulWidget {
  final MyRecorder recorder;
  final Function(List<double>?) newScan;
  final void Function() onStart;

  const ListenForFire({
    super.key,
    required this.recorder,
    required this.newScan,
    required this.onStart,
  });

  @override
  State<StatefulWidget> createState() {
    return ListenForFireState();
  }
}

class ListenForFireState extends State<ListenForFire> {
  bool recording = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () {
            if (recording) {
              stopRecording();
            } else {
              startRecording();
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: recording ? Colors.red.shade300 : Colors.green,
          ),
          child: recording
              ? const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 40,
                )
              : const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
        ),
      ],
    );
  }

  void startRecording() async {
    widget.onStart();

    setState(() {
      recording = true;
    });

    if (widget.recorder.isRecording) {
      await widget.recorder.stop();
    }

    final stream = await widget.recorder.start();

    final completer = Completer();
    stream.listen(
      (event) {
        final d = event.buffer.asInt16List();
        widget.recorder.stft.run(d.map((e) => 1.0 * e).toList(), (p0) {
          var res = p0.discardConjugates().magnitudes();

          final median = (List.of(res)..sort())[(res.length * 0.30).toInt()];
          for (int i = 0; i < res.length; ++i) {
            res[i] = max(0, res[i] - median);
          }

          for (int i = 0; i < ignoreLowestFreqs; ++i) {
            res[i] = 0;
          }

          widget.newScan(simpleMovingAverage(res));
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
  }

  void stopRecording() async {
    await widget.recorder.stop();
  }
}
