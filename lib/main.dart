import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:async/async.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Stream<Uint8List> chunkStream(Stream<Uint8List> source, int chunkSize) async* {
  final reader = ChunkedStreamReader(source);
  while (true) {
    final chunk = await reader.readBytes(chunkSize);
    if (chunk.isEmpty) {
      break; // End of source stream
    }
    yield Uint8List.fromList(chunk);
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSoundRecorder recorder = FlutterSoundRecorder();

  int counter = 0;
  Int16List? data;

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
                child: const Text("play"),
                onPressed: () async {
                  var status = await Permission.microphone.request();
                  if (status != PermissionStatus.granted) {
                    print('Microphone permission not granted');
                  }

                  if (recorder.isRecording) {
                    await recorder.stopRecorder();
                  }

                  await recorder.openRecorder();
                  var recordingDataController = StreamController<Food>();

                  final chunkedReader =
                      chunkStream(recordingDataController.stream.map((buffer) {
                    if (buffer is FoodData && buffer.data != null) {
                      return buffer.data!;
                    } else {
                      return Uint8List(0);
                    }
                  }), 2048);

                  chunkedReader.listen((event) {
                    setState(() {
                      data = event.buffer.asInt16List();
                      counter++;
                    });
                  });
                  await recorder.startRecorder(
                    toStream: recordingDataController.sink,
                    codec: Codec.pcm16,
                    numChannels: 1,
                    sampleRate: 16000,
                  );
                  await Future.delayed(const Duration(seconds: 5));
                  await recorder.closeRecorder();
                  setState(() {
                    data = null;
                  });
                },
              ),
            ),
            if (data != null)
              PolygonWaveform(
                samples: data!.map((e) => (1.0 * e)).toList(),
                height: 300,
                width: MediaQuery.of(context).size.width,
              ),
          ],
        )),
      ),
    );
  }
}
