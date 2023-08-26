import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
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

class MyRecorder {
  FlutterSoundRecorder recorder = FlutterSoundRecorder();
  StreamController<Food> recordingDataController = StreamController<Food>();

  final int chunkSize;

  FFT fft;
  STFT stft;

  MyRecorder({required this.chunkSize})
      : fft = FFT(chunkSize),
        stft = STFT(chunkSize, Window.hanning(chunkSize)) {}

  Future<void> stop() async {
    await recorder.stopRecorder();
    await recorder.closeRecorder();
    await recordingDataController.close();
  }

  Future<Stream<Int16List>> start() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    if (recorder.isRecording) await stop();

    await recorder.openRecorder();

    recordingDataController = StreamController<Food>();

    final chunkedReader =
        chunkStream(recordingDataController.stream.map((buffer) {
      if (buffer is FoodData) {
        final data = buffer.data;
        if (data != null) return data.buffer.asInt16List();
      }
      return Int16List(0);
    }), chunkSize);

    await recorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    return chunkedReader;
  }

  get isRecording {
    return recorder.isRecording;
  }
}
