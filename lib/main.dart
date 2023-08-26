import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSoundRecorder recorder = FlutterSoundRecorder();

  String? data;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
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

                  await recorder.openRecorder();

                  var recordingDataController = StreamController<Food>();
                  recordingDataController.stream.listen((buffer) {
                    if (buffer is FoodData) {
                      setState(() {
                        data = "got data ${buffer.data}";
                      });
                    }
                  });
                  await recorder.startRecorder(
                    toStream: recordingDataController.sink,
                    codec: Codec.pcm16,
                    numChannels: 1,
                    sampleRate: 160000,
                  );
                  await Future.delayed(const Duration(seconds: 1));
                  await recorder.closeRecorder();
                },
              ),
            ),
            if (data != null) Text(data!.substring(0, 200)),
          ],
        )),
      ),
    );
  }
}
