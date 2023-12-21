import 'dart:collection';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

// source: https://pub.dev/packages/just_audio#working-with-stream-audio-sources
class ByteAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  ByteAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

class AudioManager {
  static HashMap<int, AudioPlayer> activePlayers = HashMap();
  static int playerCounter = 0;

  static Future<void> play(AudioSource source) async {
    final activePlayers = AudioManager.activePlayers;

    final player = AudioPlayer();
    await player.setAudioSource(source);

    final id = playerCounter++;
    activePlayers[id] = player;

    await player.play();
    await player.dispose();

    activePlayers.remove(id);
  }

  static void killAll() {
    final activePlayers = AudioManager.activePlayers;
    AudioManager.activePlayers = HashMap();
    for (final player in activePlayers.values) {
      player.stop();
    }
  }
}
