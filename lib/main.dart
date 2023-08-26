import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fftea/fftea.dart';

Stream<Int16List> chunkStream(Stream<Int16List> source, int chunkSize) async* {
  final reader = ChunkedStreamReader(source);
  while (true) {
    final chunk = await reader.readBytes(chunkSize);
    if (chunk.isEmpty) {
      break; // End of source stream
    }
    yield Int16List.fromList(chunk);
  }
}

const chunkSize = 2048;

final fft = FFT(chunkSize);
final fftWindow = Window.hanning(chunkSize);
final stft = STFT(chunkSize, fftWindow);

void main() => runApp(const MyApp());

class MyRecorder {
  FlutterSoundRecorder recorder = FlutterSoundRecorder();

  Future<void> stop() async {
    await recorder.stopRecorder();
    await recorder.closeRecorder();
  }

  Future<Stream<Int16List>> start() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    if (recorder.isRecording) await stop();

    await recorder.openRecorder();
    final recordingDataController = StreamController<Food>();

    final chunkedReader =
        chunkStream(recordingDataController.stream.map((buffer) {
      if (buffer is FoodData) {
        final data = buffer.data;
        if (data != null) return data.buffer.asInt16List();
      }
      return Int16List(0);
    }), chunkSize * 2);

    await recorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 32000,
    );

    return chunkedReader;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final recorder = MyRecorder();

  Float64List? sample;
  Float64List? spec;
  List<double> comparisons = <double>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                child: const Text("take sample"),
                onPressed: () async {
                  final chunkedReader = await recorder.start();

                  final specs = <Float64List>[];
                  chunkedReader.listen((event) {
                    final d = event.buffer.asInt16List();
                    stft.run(d.map((e) => 1.0 * e).toList(), (p0) {
                      specs.add(p0.discardConjugates().magnitudes());
                    });
                  });

                  await Future.delayed(const Duration(seconds: 1));

                  await recorder.stop();

                  final spec = specs.first;
                  specs.forEach((dd) {
                    for (int i = 0; i < spec.length; ++i) {
                      spec[i] += dd[i];
                    }
                  });

                  final median = (List.of(spec)
                        ..sort((a, b) => a.compareTo(b)))[
                      (spec.length * 0.25).toInt()];
                  for (int i = 0; i < spec.length; ++i) spec[i] -= median;

                  for (int i = 0; i < 100; ++i) spec[i] = 0;

                  double sigma = 0;
                  for (int i = 0; i < spec.length; ++i)
                    sigma += spec[i] * spec[i];
                  sigma = sqrt(sigma / spec.length);
                  sigma = 1;

                  for (int i = 0; i < spec.length; ++i) spec[i] /= sigma * 0.01;
                  setState(() {
                    sample = spec;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                child: const Text("record"),
                onPressed: () async {
                  final chunkedReader = await recorder.start();
                  chunkedReader.listen((event) {
                    final d = event.buffer.asInt16List();
                    stft.run(d.map((e) => 1.0 * e).toList(), (p0) {
                      final data = p0.discardConjugates().magnitudes();

                      final s = sample;
                      double v = 0;
                      if (s != null) {
                        int offet = 100;
                        double m0 = 0;
                        for (int i = 0; i < data.length; ++i) {
                          m0 += data[i];
                        }
                        m0 /= (data.length - offet);

                        double v2 = 0;
                        for (int i = offet; i < data.length; ++i) {
                          v2 += data[i] * data[i];
                        }
                        v2 = sqrt(v2 / data.length);

                        for (int i = offet; i < data.length; ++i) {
                          v += (data[i] - m0) * s[i];
                        }
                        v /= (data.length - offet);
                        v /= v2;
                      }

                      setState(() {
                        spec = data;
                        comparisons.add(v);
                        comparisons = comparisons.sublist(
                            max(0, comparisons.length - 200),
                            comparisons.length);
                      });
                    });
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                child: const Text("stop"),
                onPressed: () async {
                  await recorder.stop();
                  setState(() {
                    spec = null;
                  });
                },
              ),
            ),
            if (sample != null)
              PolygonWaveform(
                samples: sample!,
                height: 200,
                width: MediaQuery.of(context).size.width,
              ),
            if (spec != null)
              PolygonWaveform(
                samples: spec!,
                height: 200,
                width: MediaQuery.of(context).size.width,
              ),
            if (comparisons.length > 0)
              PolygonWaveform(
                samples: comparisons,
                height: 200,
                width: MediaQuery.of(context).size.width,
              ),
          ],
        )),
      ),
    );
  }
}
