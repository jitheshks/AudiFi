import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/data/services/just_audio_player_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JustAudioPlayerService', () {
    test(
      'instantiates with custom or default AudioPlayer without throwing',
      () {
        final service = JustAudioPlayerService();
        expect(service, isA<AudioPlayerService>());
        expect(service.isPlaying, isFalse);
        expect(service.currentPosition, Duration.zero);
        expect(service.currentDuration, isNull);
      },
    );

    test('accepts custom audioLoadConfiguration without throwing', () {
      final service = JustAudioPlayerService(
        audioLoadConfiguration: const AudioLoadConfiguration(
          androidLoadControl: AndroidLoadControl(
            bufferForPlaybackDuration: Duration(milliseconds: 1000),
          ),
        ),
      );
      expect(service, isA<AudioPlayerService>());
    });

    test(
      'dispose cleans up controllers and streams gracefully and is idempotent',
      () async {
        final service = JustAudioPlayerService();
        expect(service.isDisposed, isFalse);
        await expectLater(service.dispose(), completes);
        expect(service.isDisposed, isTrue);

        // Calling dispose a second time is safe and idempotent
        await expectLater(service.dispose(), completes);
        expect(service.isDisposed, isTrue);
      },
    );

    test(
      'commands on disposed player service return safely without throwing',
      () async {
        final service = JustAudioPlayerService();
        await service.dispose();

        await expectLater(service.play(), completes);
        await expectLater(service.pause(), completes);
        await expectLater(service.stop(), completes);
        await expectLater(service.seek(const Duration(seconds: 10)), completes);
        await expectLater(
          service.setAudioUrl('https://example.com/audio.mp3'),
          completes,
        );
        await expectLater(service.setVolume(0.8), completes);
        await expectLater(service.setSpeed(1.5), completes);
      },
    );
  });
}
