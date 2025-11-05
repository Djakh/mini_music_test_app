import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/presentation/notifiers/download_notifier.dart';
import 'package:mini_music_test_app/presentation/pages/catalog_page.dart';

class _FakeDownloadNotifier extends StateNotifier<Map<String, DownloadInfo>> {
  _FakeDownloadNotifier() : super(const {});
}

void main() {
  final sampleTracks = [
    const Track(
      id: '1',
      title: 'Sunrise',
      artist: 'Lofi Lab',
      duration: 180,
      audioUrl: 'https://example.com/sunrise.mp3',
      coverUrl: 'assets/covers/sunrise.png',
    ),
    const Track(
      id: '2',
      title: 'Night Drive',
      artist: 'Synth Waves',
      duration: 200,
      audioUrl: 'https://example.com/night.mp3',
      coverUrl: 'assets/covers/night_drive.png',
    ),
  ];

  testWidgets('search filters catalog items', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => sampleTracks),
       //   downloadNotifierProvider.overrideWith((ref) => _FakeDownloadNotifier()),
          mediaItemStreamProvider.overrideWith((ref) => Stream<MediaItem?>.value(null)),
          positionStreamProvider.overrideWith((ref) => Stream.value(Duration.zero)),
          durationStreamProvider.overrideWith((ref) => Stream.value(Duration.zero)),
          bufferedPositionStreamProvider.overrideWith((ref) => Stream.value(Duration.zero)),
          playingStreamProvider.overrideWith((ref) => Stream.value(false)),
          queueStreamProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: CatalogPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Night Drive'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Night');
    await tester.pumpAndSettle();

    expect(find.text('Sunrise'), findsNothing);
    expect(find.text('Night Drive'), findsOneWidget);
  });
}
